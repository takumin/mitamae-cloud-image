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
	inst_multiple ip sed

	inst_hook pre-pivot 90 "${moddir}/cloud-init-nocloud-seednet.sh"
	inst_hook cleanup 90 "${moddir}/live-network.sh"

	# systemd-networkd-wait-online waits for every interface by default, and dracut configures every one of
	# them for DHCP, so a cable left unplugged or the wireless interface held the boot for the whole timeout.
	if dracut_module_included systemd-networkd; then
		mkdir -p "${initdir}${systemdsystemunitdir}/systemd-networkd-wait-online.service.d"
		{
			echo '[Service]'
			echo 'ExecStart='
			echo "ExecStart=${systemdutildir}/systemd-networkd-wait-online --any"
		} > "${initdir}${systemdsystemunitdir}/systemd-networkd-wait-online.service.d/90-mitamae-live.conf"
	fi
}
