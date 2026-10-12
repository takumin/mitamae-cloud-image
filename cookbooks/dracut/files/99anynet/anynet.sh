#!/bin/sh
# vim: set noet :

command -v getarg > /dev/null || . /lib/dracut-lib.sh

# The root keeps /run, so the network config the initrd wrote there would configure the root as well: the
# catch-all DHCP of dracut, and what systemd-network-generator writes for ip=. Where seednet brought up the
# network from a NoCloud network-config, it has removed the catch-all and the root keeps its files, which
# seednet.service writes again for the root.
drop_initrd_network() {(
	if [ -e /run/seednet/source ]; then
		return
	fi

	rm -f /run/systemd/network/*.network
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
