#!/bin/bash
# vim: set noet :

set -eu

################################################################################
# Default Variables
################################################################################

# USB Device ID
: "${USB_NAME:="$1"}"

# LiveUSB Mount Point
: "${LIVEUSB:="/run/liveusb"}"

# Cloud-Init Mount Point
: "${CIDATA:="/run/cidata"}"

# Destination Directory
: "${DESTDIR:="$(cd "$(dirname "$0")/.."; pwd)/releases"}"

# Linux Distribution
# Value:
# - debian
# - ubuntu
: "${DISTRIB:="debian"}"

# Release Codename
# Value:
# - bookworm
# - trixie
# - noble
# - resolute
: "${RELEASE:="trixie"}"

# Kernel Package
# Value:
# - raspberrypi
: "${KERNEL:="raspberrypi"}"

# Package Selection
# Value:
# - server
# - desktop
# - kodi
# - kodi-car
: "${PROFILE:="server"}"

# CPU Architecture
# Value:
# - amd64
# - arm64
: "${ARCH:="arm64"}"

# Partition Initialize
# Value:
# - false: keep the partition table and SRVDATA, and rewrite only BOOT and CIDATA
# - true:  wipe the disk and create every partition
: "${INITIALIZE:="false"}"

# Video Output
# Value:
# - hdmi:      the HDMI ports
# - composite: the NTSC-J 480i on the 3.5mm jack, along with the analog audio
: "${VIDEO_OUTPUT:="hdmi"}"

# Wi-Fi Access Point Credentials (kodi-car)
# Written to wifi-ap.conf on the boot partition, where each one set overrides the one in the image.
: "${WIFI_AP_SSID:=""}"
: "${WIFI_AP_PASSPHRASE:=""}"

################################################################################
# Local Variables
################################################################################

# Destination Directory
DESTDIR="${DESTDIR}/${DISTRIB}/${RELEASE}/${KERNEL}/${ARCH}/${PROFILE}"

# Get Real Disk Path
USB_PATH="$(realpath "/dev/disk/by-id/${USB_NAME}")"

################################################################################
# Check Variables
################################################################################

# Check Variable
if [ "x${USB_NAME}" = "x" ]; then
  # Error...
  exit 1
fi

# Check Video Output
case "${VIDEO_OUTPUT}" in
	hdmi|composite) ;;
	*) echo "Unknown VIDEO_OUTPUT: ${VIDEO_OUTPUT}" >&2; exit 1 ;;
esac

################################################################################
# Functions
################################################################################

# Print the partitions of the disk with the partition label
find_partition() {
	lsblk -nrpo NAME,PARTLABEL "${USB_PATH}" | awk -v label="$1" '$2 == label {print $1}'
}

# Unmount every mount point of the device
unmount_device() {
	awk -v dev="$1" '$1 == dev {print $2}' /proc/mounts | sort -r | xargs --no-run-if-empty umount
}

################################################################################
# Required Packages
################################################################################

# Install Require Packages
# Rewriting the existing partitions needs no extra package, so it also runs on the Raspberry Pi booted from
# the disk.
if [ "${INITIALIZE}" = "true" ]; then
	dpkg -l | awk '{print $2}' | grep -qs '^gdisk$'      || apt-get -y install gdisk
	dpkg -l | awk '{print $2}' | grep -qs '^dosfstools$' || apt-get -y install dosfstools
	dpkg -l | awk '{print $2}' | grep -qs '^xfsprogs$'   || apt-get -y install xfsprogs
	dpkg -l | awk '{print $2}' | grep -qs '^parted$'     || apt-get -y install parted
fi

################################################################################
# Cleanup
################################################################################

# Unmount Working Directory
awk '{print $2}' /proc/mounts | grep -s "${LIVEUSB}" | sort -r | xargs --no-run-if-empty umount
awk '{print $2}' /proc/mounts | grep -s "${CIDATA}" | sort -r | xargs --no-run-if-empty umount

################################################################################
# Initialize
################################################################################

# Create Working Directory
mkdir -p "${LIVEUSB}"
mkdir -p "${CIDATA}"

################################################################################
# Partition
################################################################################

if [ "${INITIALIZE}" = "true" ]; then
	# Unmount Disk Drive
	awk '{print $1}' /proc/mounts | grep -s "${USB_PATH}" | sort -r | xargs --no-run-if-empty umount

	# Clear Partition Table
	sgdisk -Z "${USB_PATH}"

	# Create GPT Partition Table
	sgdisk -o "${USB_PATH}"

	# Create Raspberry Pi Boot Partition
	sgdisk -n 1::+4G  -c 1:"BOOT"    -t 1:0700 "${USB_PATH}"

	# Create Cloud-Init Data Partition
	sgdisk -n 2::+64M -c 2:"CIDATA"  -t 2:0700 "${USB_PATH}"

	# Create Site-specific Data Partition
	# The persistent cookbook mounts it on /srv by the partition label.
	sgdisk -n 3::-1   -c 3:"SRVDATA" -t 3:8306 "${USB_PATH}"

	# Do Not Automount
	sgdisk -A 1:set:63 "${USB_PATH}"
	sgdisk -A 2:set:63 "${USB_PATH}"

	# Wait Probe
	sleep 1

	# Partition Probe
	partprobe -s

	# Wait Probe
	udevadm settle
fi

# Get Real Path
BOOTPT="$(find_partition BOOT)"
CIDATAPT="$(find_partition CIDATA)"
SRVDATAPT="$(find_partition SRVDATA)"

# Check Partition
for LABEL in BOOT CIDATA SRVDATA; do
	if [ "$(find_partition "${LABEL}" | wc -l)" -ne 1 ]; then
		echo "${USB_PATH}: needs exactly one ${LABEL} partition, or INITIALIZE=true to wipe the disk" >&2
		exit 1
	fi
done

################################################################################
# Format
################################################################################

if [ "${INITIALIZE}" = "true" ]; then
	# Format Partition
	mkfs.vfat -F 32 -n 'BOOT' -v "${BOOTPT}"
	mkfs.vfat -F 32 -n 'CIDATA' -v "${CIDATAPT}"
	mkfs.xfs -f -L 'SRVDATA' "${SRVDATAPT}"
else
	# SRVDATA stays mounted, and only the partitions to rewrite are released.
	unmount_device "${BOOTPT}"
	unmount_device "${CIDATAPT}"
fi

################################################################################
# Mount
################################################################################

# Mount Partition
mount -t vfat -o codepage=932,iocharset=utf8 "${BOOTPT}" "${LIVEUSB}"
mount -t vfat -o codepage=932,iocharset=utf8 "${CIDATAPT}" "${CIDATA}"

# Clear Partition
# The kept partitions are emptied instead of formatted, since the booted Raspberry Pi has no mkfs.vfat.
find "${LIVEUSB}" -mindepth 1 -delete
find "${CIDATA}" -mindepth 1 -delete

################################################################################
# Files
################################################################################

# Sync Release Files
rsync -rlptDhv --exclude 'packages.manifest' --exclude 'rootfs.*' --progress "${DESTDIR}/" "${LIVEUSB}/"

# Composite Output
# The Raspberry Pi 4 keeps the composite output off unless enable_tvout=1. The HDMI ports are removed, so
# that Kodi picks the composite connector and ALSA the analog audio as the default card.
# dtparam=audio=on has to come before the vc4 overlay, where the same name switches the HDMI audio.
if [ "${VIDEO_OUTPUT}" = "composite" ]; then
	sed -i -e 's/^dtoverlay=vc4-kms-v3d-pi4$/enable_tvout=1\ndtparam=audio=on\n&,composite,nohdmi/' "${LIVEUSB}/config.txt"
	grep -qs '^dtoverlay=vc4-kms-v3d-pi4,composite,nohdmi$' "${LIVEUSB}/config.txt"
fi

# Live Boot Directory
mkdir -p "${LIVEUSB}/live"

# Copy to Rootfs Files
cp "${DESTDIR}/rootfs.squashfs" "${LIVEUSB}/live/filesystem.squashfs"
cp "${DESTDIR}/packages.manifest" "${LIVEUSB}/live/filesystem.packages"

# Generate cmdline.txt
# ds=nocloud stays in dsmode=local on purpose: the seed is on the cidata partition and the USB may boot
# without a network.
# anynet runs DHCP on every wired interface, since the cidata seed has no network-config; the desktop profiles
# leave the network to NetworkManager.
CMDLINE='console=ttyS0,115200 console=tty1 boot=live ds=nocloud toram noeject nopersistence'
case "${PROFILE}" in
	desktop*) ;;
	*) CMDLINE="${CMDLINE} anynet" ;;
esac
# The car display runs at 480p, and Kodi keeps the mode the console was set to.
# The composite output is shrunk by the margins, since the display overscans the analog picture.
if [ "${VIDEO_OUTPUT}" = "composite" ]; then
	CMDLINE="${CMDLINE} video=Composite-1:720x480@60ie,tv_mode=NTSC-J,margin_left=24,margin_right=24,margin_top=8,margin_bottom=16"
else
	case "${PROFILE}" in
		kodi-car) CMDLINE="${CMDLINE} video=HDMI-A-1:720x480@60 video=HDMI-A-2:720x480@60" ;;
	esac
fi
echo "${CMDLINE}" > "${LIVEUSB}/cmdline.txt"

# Wi-Fi Access Point Credentials
if [ -n "${WIFI_AP_SSID}" ] || [ -n "${WIFI_AP_PASSPHRASE}" ]; then
	{
		[ -z "${WIFI_AP_SSID}" ] || printf 'ssid=%s\n' "${WIFI_AP_SSID}"
		[ -z "${WIFI_AP_PASSPHRASE}" ] || printf 'wpa_passphrase=%s\n' "${WIFI_AP_PASSPHRASE}"
	} > "${LIVEUSB}/wifi-ap.conf"
fi

################################################################################
# Cloud-Init
################################################################################

# Metadata
cat > "${CIDATA}/meta-data" << __EOF__
instance-id: iid-live-${DISTRIB}-${RELEASE}
hostname: live-${DISTRIB}-${RELEASE}
__EOF__

# Userdata
cat > "${CIDATA}/user-data" << '__EOF__'
#cloud-config
disable_ec2_metadata: true
disable_root: true
ssh_pwauth: false
ssh_deletekeys: true
ssh_genkeytypes: [rsa, ecdsa, ed25519]
ssh_quiet_keygen: true
manage_etc_hosts: localhost
preserve_hostname: false
timezone: Asia/Tokyo
users:
- name: takumi
  gecos: Takumi Takahashi
  groups: adm, users, staff, sudo, plugdev, netdev, bluetooth, dialout, cdrom, floppy, audio, video
  passwd: "$6$byTym7UB$oQJeq6Sy.t9ivuVJmLq8zqeT7lcsn42SMuM1Z2sRozsMCTUxEhjD9L6ZvN6U6Ss8ApG3kNO6S.1m2XrDv73Wc/"
  lock_passwd: false
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: "/bin/bash"
  ssh_authorized_keys:
  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOUnX4dcl4MGhuqVyHJzbUG11eHJfN2iyTu3LSJt8x3V
    takumiiinn@gmail.com
__EOF__

################################################################################
# Cleanup
################################################################################

# Unmount Working Directory
awk '{print $2}' /proc/mounts | grep -s "${LIVEUSB}" | sort -r | xargs --no-run-if-empty umount
awk '{print $2}' /proc/mounts | grep -s "${CIDATA}" | sort -r | xargs --no-run-if-empty umount

# Cleanup Working Directory
rmdir "${LIVEUSB}"
rmdir "${CIDATA}"

# Disk Sync
sync;sync;sync
