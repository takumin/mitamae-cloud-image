#!/bin/bash
# vim: set noet :

# Included only when dracut.conf.d asks for it.
check() {
	return 255
}

depends() {
	echo dmsquash-live livenet url-lib
	return 0
}

install() {
	inst_hook cleanup 90 "${moddir}/live-network.sh"
}
