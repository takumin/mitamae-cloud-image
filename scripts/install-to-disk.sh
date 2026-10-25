#!/bin/bash
# vim: set noet :

set -eu

################################################################################
# Default Variables
################################################################################

# diskform Declaration
: "${DECLARATION:="${1:-}"}"

# Script Directory
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

# diskform Binary
: "${DISKFORM:="${SCRIPT_DIR}/diskform"}"

# Root Filesystem Image
# generate-bootable-usb.sh puts this script in /install on the boot partition, next to /LiveOS.
: "${SQUASHFS:="${SCRIPT_DIR}/../LiveOS/squashfs.img"}"

# Cloud-Init Seed Directory
# Without it, the seed is copied from the cidata partition of the USB.
: "${SEED_DIR:=""}"

# Install Root Mount Point
: "${TARGET:="/run/target"}"

# Cloud-Init Mount Point
: "${CIDATA:="/run/cidata"}"

################################################################################
# Check Variables
################################################################################

if [ "x${DECLARATION}" = "x" ]; then
	echo "usage: $0 <diskform declaration>" >&2
	exit 1
fi

# systemd-boot only boots on UEFI.
if [ ! -d /sys/firmware/efi ]; then
	echo "not booted on UEFI" >&2
	exit 1
fi

if [ ! -f "${SQUASHFS}" ]; then
	echo "${SQUASHFS} not found" >&2
	exit 1
fi

################################################################################
# Storage
################################################################################

# apply shows the operations and asks for yes; a disk with existing storage needs diskform destroy first.
"${DISKFORM}" apply "${DECLARATION}"
mkdir -p "${TARGET}"
"${DISKFORM}" mount --root "${TARGET}" "${DECLARATION}"

################################################################################
# Root Filesystem
################################################################################

unsquashfs -f -d "${TARGET}" "${SQUASHFS}"

################################################################################
# Fstab
################################################################################

# The mounts of diskform under the target, with the options the kernel shows; subvolid is left out since
# subvol names the same subvolume and survives a recreated one.
findmnt -R -n -l -o SOURCE,TARGET,FSTYPE,OPTIONS "${TARGET}" | while read -r SOURCE MOUNTPOINT FSTYPE OPTIONS; do
	# btrfs shows the subvolume after the device, as in /dev/nvme0n1p2[/@home].
	UUID="$(blkid -s UUID -o value "${SOURCE%%\[*}")"
	MOUNTPOINT="${MOUNTPOINT#"${TARGET}"}"
	OPTIONS="$(echo "${OPTIONS}" | tr ',' '\n' | grep -v '^subvolid=' | paste -sd ',')"

	case "${FSTYPE}:${MOUNTPOINT:-/}" in
		btrfs:*) PASSNO=0 ;;
		*:/)     PASSNO=1 ;;
		*)       PASSNO=2 ;;
	esac

	printf 'UUID=%s\t%s\t%s\t%s\t0\t%s\n' "${UUID}" "${MOUNTPOINT:-/}" "${FSTYPE}" "${OPTIONS}" "${PASSNO}"
done > "${TARGET}/etc/fstab"

################################################################################
# Kernel Parameter
################################################################################

read -r ROOT_SOURCE ROOT_FSTYPE ROOT_OPTIONS < <(findmnt -n -o SOURCE,FSTYPE,OPTIONS --mountpoint "${TARGET}")

CMDLINE="root=UUID=$(blkid -s UUID -o value "${ROOT_SOURCE%%\[*}") rw"

if [ "${ROOT_FSTYPE}" = "btrfs" ]; then
	ROOT_SUBVOL="$(echo "${ROOT_OPTIONS}" | tr ',' '\n' | sed -n 's/^subvol=//p')"
	if [ "${ROOT_SUBVOL:-/}" != "/" ]; then
		CMDLINE="${CMDLINE} rootflags=subvol=${ROOT_SUBVOL}"
	fi
fi

# kernel-install reads the kernel command line of the boot entries here.
echo "${CMDLINE}" > "${TARGET}/etc/kernel/cmdline"

################################################################################
# Boot Loader
################################################################################

mount -t proc proc "${TARGET}/proc"
# Slaved, so the recursive unmount of the binds below does not propagate to /sys and /dev of the live root.
mount --rbind --make-rslave /sys "${TARGET}/sys"
mount --rbind --make-rslave /dev "${TARGET}/dev"
mount -t tmpfs tmpfs "${TARGET}/run"

# bootctl finds the EFI system partition at /efi, /boot or /boot/efi. The machine-id is still empty, so the boot
# entries are named after the ID of os-release.
BOOTCTL_OPTIONS=(--entry-token=os-id)

# bootctl since 258 leaves the EFI variables alone in a chroot unless told to; 257 has no such option and
# touches them.
if chroot "${TARGET}" bootctl --help | grep -q -- '--variables='; then
	BOOTCTL_OPTIONS+=(--variables=yes)
fi

chroot "${TARGET}" bootctl install "${BOOTCTL_OPTIONS[@]}"

# The initrd built with the image boots on any machine, so it goes in as it is.
for KERNEL in "${TARGET}"/boot/vmlinuz-*; do
	VERSION="${KERNEL##*/vmlinuz-}"
	chroot "${TARGET}" kernel-install add "${VERSION}" "/boot/vmlinuz-${VERSION}" "/boot/initrd.img-${VERSION}"
done

umount -R "${TARGET}/run"
umount -R "${TARGET}/dev"
umount -R "${TARGET}/sys"
umount -R "${TARGET}/proc"

################################################################################
# Cloud-Init
################################################################################

# The minimal roles have no Cloud-Init.
if [ -x "${TARGET}/usr/bin/cloud-init" ]; then
	if [ "x${SEED_DIR}" = "x" ]; then
		mkdir -p "${CIDATA}"
		mount -o ro /dev/disk/by-label/CIDATA "${CIDATA}"
		SEED="${CIDATA}"
	else
		SEED="${SEED_DIR}"
	fi

	mkdir -p "${TARGET}/var/lib/cloud/seed/nocloud"
	for FILE in meta-data user-data vendor-data network-config; do
		if [ -f "${SEED}/${FILE}" ]; then
			install -m 0600 "${SEED}/${FILE}" "${TARGET}/var/lib/cloud/seed/nocloud/${FILE}"
		fi
	done

	if [ "x${SEED_DIR}" = "x" ]; then
		umount "${CIDATA}"
		rmdir "${CIDATA}"
	fi
fi

################################################################################
# Cleanup
################################################################################

"${DISKFORM}" unmount --root "${TARGET}" "${DECLARATION}"

# Disk Sync
sync;sync;sync
