#!/bin/bash
# vim: set noet :

set -eu

################################################################################
# Default Variables
################################################################################

# USB Device ID
: "${USB_NAME:="$1"}"

# Root File System Mount Point
: "${WORKDIR:="/run/liveusb"}"

# Destination Directory
: "${DESTDIR:="$(cd "$(dirname "$0")/.."; pwd)/releases"}"

# Linux Distribution
# Value: [debian|ubuntu]
: "${DISTRIB:="ubuntu"}"

# Release Codename
# Value: [noble]
: "${RELEASE:="noble"}"

# Kernel Package
# Value: [generic|generic-hwe]
: "${KERNEL:="generic-hwe"}"

# Package Selection
# Value: [server|server-nvidia|server-nvidia-cuda|desktop|desktop-nvidia|desktop-nvidia-cuda]
: "${PROFILE:="server"}"

# CPU Architecture
# Value: [amd64|arm64]
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
awk '{print $2}' /proc/mounts | grep -s "${WORKDIR}" | sort -r | xargs --no-run-if-empty umount

################################################################################
# Initialize
################################################################################

# Create Working Directory
mkdir -p "${WORKDIR}"

################################################################################
# Partition
################################################################################

# Clear Partition Table
sgdisk -Z "${USB_PATH}"

# Create GPT Partition Table
sgdisk -o "${USB_PATH}"

# Create BIOS Boot Partition
sgdisk -a 1 -n 1::2047 -c 1:"BIOS" -t 1:ef02 "${USB_PATH}"

# Create EFI System Partition
sgdisk      -n 2::+4G  -c 2:"ESP"  -t 2:ef00 "${USB_PATH}"

# Create USB Data Partition
sgdisk      -n 3::-1   -c 3:"USB"  -t 3:0700 "${USB_PATH}"

# Wait Probe
sleep 1

# Get Real Path
ESPPT="$(realpath "/dev/disk/by-id/${USB_NAME}-part2")"
USBPT="$(realpath "/dev/disk/by-id/${USB_NAME}-part3")"

# Get UUID
UUID="$(blkid -p -s UUID -o value "${ESPPT}")"

################################################################################
# Format
################################################################################

# Format Partition
mkfs.vfat -F 32 -n 'ESP' -v "${ESPPT}"
mkfs.vfat -F 32 -n 'USB' -v "${USBPT}"

################################################################################
# Mount
################################################################################

# Mount Partition
mount -t vfat -o codepage=932,iocharset=utf8 "${ESPPT}" "${WORKDIR}"

################################################################################
# Directory
################################################################################

# Require Directory
mkdir -p "${WORKDIR}/boot"
mkdir -p "${WORKDIR}/live"

################################################################################
# Files
################################################################################

# Kernel
cp "${DESTDIR}/vmlinuz" "${WORKDIR}/live/vmlinuz"

# Initramfs
cp "${DESTDIR}/initrd.img" "${WORKDIR}/live/initrd.img"

# Rootfs
cp "${DESTDIR}/rootfs.squashfs" "${WORKDIR}/live/rootfs.squashfs"

################################################################################
# Grub
################################################################################

# Grub Install
grub-install --target=i386-pc --recheck --boot-directory="${WORKDIR}/boot" "${USB_PATH}" --force
grub-install --target=x86_64-efi --recheck --boot-directory="${WORKDIR}/boot" --efi-directory="${WORKDIR}" --removable

# Grub Config
cat > "${WORKDIR}/boot/grub/grub.cfg" << __EOF__
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
	linux /live/vmlinuz boot=live bootfrom=removable-usb toram noeject nopersistence cgroup_enable=memory swapaccount=1 silent quiet ---
	initrd /live/initrd.img
}
__EOF__

################################################################################
# Cleanup
################################################################################

# Unmount Working Directory
awk '{print $2}' /proc/mounts | grep -s "${WORKDIR}" | sort -r | xargs --no-run-if-empty umount

# Cleanup Working Directory
rmdir "${WORKDIR}"

# Disk Sync
sync;sync;sync
