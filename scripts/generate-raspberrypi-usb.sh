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
# - bullseye
# - bookworm
# - jammy
# - noble
: "${RELEASE:="bookworm"}"

# Kernel Package
# Value:
# - raspberrypi
: "${KERNEL:="raspberrypi"}"

# Package Selection
# Value:
# - server
# - desktop
: "${PROFILE:="server"}"

# CPU Architecture
# Value:
# - amd64
# - arm64
: "${ARCH:="arm64"}"

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

################################################################################
# Required Packages
################################################################################

# Install Require Packages
dpkg -l | awk '{print $2}' | grep -qs '^gdisk$'      || apt-get -y install gdisk
dpkg -l | awk '{print $2}' | grep -qs '^dosfstools$' || apt-get -y install dosfstools

################################################################################
# Cleanup
################################################################################

# Unmount Disk Drive
awk '{print $1}' /proc/mounts | grep -s "${USB_PATH}" | sort -r | xargs --no-run-if-empty umount

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

# Clear Partition Table
sgdisk -Z "${USB_PATH}"

# Create GPT Partition Table
sgdisk -o "${USB_PATH}"

# Create Raspberry Pi Boot Partition
sgdisk -n 1::+4G  -c 1:"BOOT"    -t 1:0700 "${USB_PATH}"

# Create Cloud-Init Data Partition
sgdisk -n 2::+64M -c 2:"CIDATA"  -t 2:0700 "${USB_PATH}"

# Create USB Data Partition
sgdisk -n 3::-1   -c 3:"USBDATA" -t 3:0700 "${USB_PATH}"

# Do Not Automount
sgdisk -A 1:set:63 "${USB_PATH}"
sgdisk -A 2:set:63 "${USB_PATH}"

# Wait Probe
sleep 1

# Partition Probe
partprobe -s

# Wait Probe
sleep 1

# Get Real Path
BOOTPT="$(realpath "/dev/disk/by-id/${USB_NAME}-part1")"
CIDATAPT="$(realpath "/dev/disk/by-id/${USB_NAME}-part2")"
USBDATAPT="$(realpath "/dev/disk/by-id/${USB_NAME}-part3")"

################################################################################
# Format
################################################################################

# Format Partition
mkfs.vfat -F 32 -n 'BOOT' -v "${BOOTPT}"
mkfs.vfat -F 32 -n 'CIDATA' -v "${CIDATAPT}"
mkfs.vfat -F 32 -n 'USBDATA' -v "${USBDATAPT}"

################################################################################
# Mount
################################################################################

# Mount Partition
mount -t vfat -o codepage=932,iocharset=utf8 "${BOOTPT}" "${LIVEUSB}"
mount -t vfat -o codepage=932,iocharset=utf8 "${CIDATAPT}" "${CIDATA}"

################################################################################
# Files
################################################################################

# Sync Release Files
rsync -rlptDhv --exclude 'packages.manifest' --exclude 'rootfs.*' --progress "${DESTDIR}/" "${LIVEUSB}/"

# Live Boot Directory
mkdir -p "${LIVEUSB}/live"

# Copy to Rootfs Files
cp "${DESTDIR}/rootfs.squashfs" "${LIVEUSB}/live/filesystem.squashfs"
cp "${DESTDIR}/packages.manifest" "${LIVEUSB}/live/filesystem.packages"

# Generate cmdline.txt
echo 'console=ttyAMA0,115200 console=tty1 boot=live ds=nocloud toram noeject nopersistence' > "${LIVEUSB}/cmdline.txt"

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
