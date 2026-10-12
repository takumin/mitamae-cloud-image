#!/bin/bash
# vim: set noet :

# Included only when dracut.conf.d asks for it.
check() {
	return 255
}

depends() {
	return 0
}

install() {
	inst_hook cleanup 90 "${moddir}/live-drop-initrd-network.sh"
}
