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
# - generic
# - generic-hwe
# - generic-backports
: "${KERNEL:="generic-backports"}"

# Package Selection
# Value:
# - server
# - server-nvidia
# - server-nvidia-cuda
# - desktop
# - desktop-nvidia
# - desktop-nvidia-cuda
# - desktop-rtl8852au-nvidia-cuda
: "${PROFILE:="desktop-rtl8852au-nvidia-cuda"}"

# CPU Architecture
# Value:
# - amd64
# - arm64
: "${ARCH:="amd64"}"

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
dpkg -l | awk '{print $2}' | grep -qs '^gdisk$'              || apt-get -y install gdisk
dpkg -l | awk '{print $2}' | grep -qs '^dosfstools$'         || apt-get -y install dosfstools
dpkg -l | awk '{print $2}' | grep -qs '^grub2-common$'       || apt-get -y install grub2-common
dpkg -l | awk '{print $2}' | grep -qs '^grub-pc-bin$'        || apt-get -y install grub-pc-bin
dpkg -l | awk '{print $2}' | grep -qs '^grub-efi-amd64-bin$' || apt-get -y install grub-efi-amd64-bin

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

# Create BIOS Boot Partition
sgdisk -a 1 -n 1::2047 -c 1:"BIOS"    -t 1:ef02 "${USB_PATH}"

# Create EFI System Partition
sgdisk      -n 2::+4G  -c 2:"ESP"     -t 2:ef00 "${USB_PATH}"

# Create Cloud-Init Data Partition
sgdisk      -n 3::+64M -c 3:"CIDATA"  -t 3:0700 "${USB_PATH}"

# Create USB Data Partition
sgdisk      -n 4::-1   -c 4:"USBDATA" -t 4:0700 "${USB_PATH}"

# Do not automount for Cloud-Init Data Partition
sgdisk -A 3:set:63 "${USB_PATH}"

# Wait Probe
sleep 1

# Partition Probe
partprobe -s

# Wait Probe
sleep 1

# Get Real Path
ESPPT="$(realpath "/dev/disk/by-id/${USB_NAME}-part2")"
CIDATAPT="$(realpath "/dev/disk/by-id/${USB_NAME}-part3")"
USBDATAPT="$(realpath "/dev/disk/by-id/${USB_NAME}-part4")"

################################################################################
# Format
################################################################################

# Format Partition
mkfs.vfat -F 32 -n 'ESP' -v "${ESPPT}"
mkfs.vfat -F 32 -n 'CIDATA' -v "${CIDATAPT}"
mkfs.vfat -F 32 -n 'USBDATA' -v "${USBDATAPT}"

################################################################################
# Mount
################################################################################

# Mount Partition
mount -t vfat -o codepage=932,iocharset=utf8 "${ESPPT}" "${LIVEUSB}"
mount -t vfat -o codepage=932,iocharset=utf8 "${CIDATAPT}" "${CIDATA}"

################################################################################
# Directory
################################################################################

# Require Directory
mkdir -p "${LIVEUSB}/boot"
mkdir -p "${LIVEUSB}/live"

################################################################################
# Files
################################################################################

# Kernel
cp "${DESTDIR}/vmlinuz" "${LIVEUSB}/live/vmlinuz"

# Initramfs
cp "${DESTDIR}/initrd.img" "${LIVEUSB}/live/initrd.img"

# Rootfs
cp "${DESTDIR}/rootfs.squashfs" "${LIVEUSB}/live/filesystem.squashfs"

# Packages
cp "${DESTDIR}/packages.manifest" "${LIVEUSB}/live/filesystem.packages"

################################################################################
# Grub
################################################################################

# Grub Install
grub-install --target=i386-pc --recheck --boot-directory="${LIVEUSB}/boot" "${USB_PATH}" --force
grub-install --target=x86_64-efi --recheck --boot-directory="${LIVEUSB}/boot" --efi-directory="${LIVEUSB}" --removable

# Get UUID
UUID="$(blkid -p -s UUID -o value "${ESPPT}")"

# Grub Config
cat > "${LIVEUSB}/boot/grub/grub.cfg" << __EOF__
if [ x\$grub_platform = xpc ]; then
	insmod vbe
fi

if [ x\$grub_platform = xefi ]; then
	insmod efi_gop
	insmod efi_uga
fi

insmod gzio

insmod font

if loadfont \${prefix}/fonts/unicode.pf2; then
	insmod gfxterm
	set gfxmode=auto
	set gfxpayload=keep
	terminal_output gfxterm
fi

insmod search
insmod search_fs_uuid

insmod part_gpt
insmod part_msdos

insmod fat

set default=0
set timeout=0

menuentry 'ubuntu' {
	search --no-floppy --fs-uuid --set=root ${UUID}
	linux /live/vmlinuz boot=live bootfrom=removable-usb toram noeject nopersistence silent quiet ---
	initrd /live/initrd.img
}
__EOF__

################################################################################
# Cloud-Init
################################################################################

# Metadata
cat > "${CIDATA}/meta-data" << '__EOF__'
instance-id: iid-debian-live
hostname: debian-live
__EOF__

# Userdata
cat > "${CIDATA}/user-data" << '__EOF__'
#cloud-config
disable_ec2_metadata: true
timezone: Asia/Tokyo
disable_root: true
ssh_deletekeys: true
ssh_genkeytypes: [rsa, ecdsa, ed25519]
ssh_quiet_keygen: true
users:
- name: takumi
  gecos: Takumi Takahashi
  groups: adm, users, staff, sudo, plugdev, netdev, bluetooth, dialout, cdrom, floppy, audio, video
  lock_passwd: false
  passwd: $6$rounds=4096$CKY3OvWE255sdkW/$RsFV2h4styw0VoMaF9hb3KOWqwsjJJQrmweA2zNE2DDR9oPUj9kzoNiVjdEvspMrvqx/CzIsS3d.ujD7MLEAo/
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
