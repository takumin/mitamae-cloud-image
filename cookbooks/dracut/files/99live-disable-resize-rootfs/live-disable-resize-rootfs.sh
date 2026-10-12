#!/bin/sh
# vim: set noet :

# The live root is an overlay on the squashfs, which has no partition or filesystem to grow.
live_disable_resize_rootfs() {(
	# dmsquash-live links the device or the image the live root came from here.
	if [ ! -h /run/initramfs/livedev ]; then
		return
	fi

	if [ ! -d "${NEWROOT}/etc/cloud/cloud.cfg.d" ]; then
		return
	fi

	echo 'resize_rootfs: false' > "${NEWROOT}/etc/cloud/cloud.cfg.d/99_disable_resize_rootfs.cfg"
)}

live_disable_resize_rootfs
