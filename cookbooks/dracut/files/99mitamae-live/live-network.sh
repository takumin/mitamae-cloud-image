#!/bin/sh
# vim: set noet :

command -v getarg > /dev/null || . /lib/dracut-lib.sh

# The root keeps /run, so the network config the initrd wrote there would configure the root as well.
drop_initrd_network() {(
	# systemd-network-generator writes one for ip=, and dracut its default for every interface.
	rm -f /run/systemd/network/*.network

	if [ ! -s "${NEWROOT}/var/lib/cloud/seed/nocloud/network-config" ]; then
		return
	fi

	# Cloud-Init refuses to rename an interface that still has the address, so release the addresses for the
	# NoCloud network-config; systemd-networkd in the initrd keeps them when it stops, and would add them
	# back while it runs.
	if [ -n "${DRACUT_SYSTEMD:-}" ]; then
		systemctl stop systemd-networkd.socket systemd-networkd.service 2> /dev/null || true
	fi

	for path in /sys/class/net/*; do
		device="${path##*/}"
		[ "${device}" = 'lo' ] && continue
		ip addr flush dev "${device}" || true
	done
)}

any_network_interfaces() {(
	# dmsquash-live links the device or the image the live root came from here.
	if [ ! -h /run/initramfs/livedev ]; then
		return
	fi

	# Opt in with anynet on the kernel command line, so that a boot which has its own network config
	# (a NoCloud network-config or NetworkManager on the desktop) keeps it
	if ! getargbool 0 anynet; then
		return
	fi

	if [ -d "${NEWROOT}/etc/cloud/cloud.cfg.d" ]; then
		{
			echo "disable_network_activation: true"
			echo "network:"
			echo "  config: disabled"
		} > "${NEWROOT}/etc/cloud/cloud.cfg.d/99_disable_network.cfg"
	fi

	mkdir -p "/run/systemd/network"

	{
		echo "[Match]"
		echo "Type=ether"
		echo ""
		echo "[Network]"
		echo "DHCP=yes"
		echo "LinkLocalAddressing=yes"
		echo "IPv6LinkLocalAddressGenerationMode=stable-privacy"
		echo "LLMNR=no"
		echo "MulticastDNS=yes"
		echo ""
		echo "[DHCPv4]"
		echo "ClientIdentifier=mac"
	} > "/run/systemd/network/99-ethernet.network"

	{
		echo "[Match]"
		echo "Type=wlan"
		echo ""
		echo "[Link]"
		echo "RequiredForOnline=no"
	} > "/run/systemd/network/99-wireless.network"

	mkdir -p "/run/systemd/system/systemd-networkd-wait-online.service.d"

	{
		echo "[Service]"
		echo "ExecStart="
		echo "ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any"
	} > "/run/systemd/system/systemd-networkd-wait-online.service.d/any-network-interfaces.conf"
)}

drop_initrd_network
any_network_interfaces
