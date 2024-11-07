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
: "${DISTRIB:="ubuntu"}"

# Release Codename
# Value:
# - bullseye
# - bookworm
# - jammy
# - noble
: "${RELEASE:="noble"}"

# Kernel Package
# Value:
# - generic
# - generic-hwe
# - generic-backports
: "${KERNEL:="generic-hwe"}"

# Package Selection
# Value:
# - server
# - server-nvidia
# - server-nvidia-cuda
# - desktop
# - desktop-nvidia
# - desktop-nvidia-cuda
# - desktop-rtl8852au-nvidia-cuda
: "${PROFILE:="minimal-bootstrap"}"

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
dpkg -l | awk '{print $2}' | grep -qs '^xfsprogs$'           || apt-get -y install xfsprogs
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
sgdisk      -n 2::+4G  -c 2:"BOOT"    -t 2:ef00 "${USB_PATH}"

# Create Cloud-Init Data Partition
sgdisk      -n 3::+64M -c 3:"CIDATA"  -t 3:0700 "${USB_PATH}"

# Create USB Data Partition
sgdisk      -n 4::-1   -c 4:"SRVDATA" -t 4:8306 "${USB_PATH}"

# Do not automount for Cloud-Init Data Partition
sgdisk -A 3:set:63 "${USB_PATH}"

# Wait Probe
sleep 1

# Partition Probe
partprobe -s

# Wait Probe
sleep 1

# Get Real Path
BOOTPT="$(realpath "/dev/disk/by-id/${USB_NAME}-part2")"
CIDATAPT="$(realpath "/dev/disk/by-id/${USB_NAME}-part3")"
SRVDATAPT="$(realpath "/dev/disk/by-id/${USB_NAME}-part4")"

################################################################################
# Format
################################################################################

# Format Partition
mkfs.vfat -F 32 -n 'BOOT' -v "${BOOTPT}"
mkfs.vfat -F 32 -n 'CIDATA' -v "${CIDATAPT}"
mkfs.xfs -f -L 'SRVDATA' "${SRVDATAPT}"

################################################################################
# Mount
################################################################################

# Mount Partition
mount -t vfat -o codepage=932,iocharset=utf8 "${BOOTPT}" "${LIVEUSB}"
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
UUID="$(blkid -p -s UUID -o value "${BOOTPT}")"

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

menuentry 'live' {
	search --no-floppy --fs-uuid --set=root ${UUID}
	linux /live/vmlinuz boot=live ds=nocloud toram noeject nopersistence
	initrd /live/initrd.img
}
__EOF__

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
