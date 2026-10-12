#!/bin/bash
# vim: set noet :

# Included only when dracut.conf.d asks for it.
check() {
	return 255
}

depends() {
	echo dmsquash-live
	return 0
}

install() {
	inst_hook pre-pivot 91 "${moddir}/live-disable-resize-rootfs.sh"
}
