#!/bin/sh
# vim: set noet :

# The root keeps /run, so the catch-all DHCP that dracut writes there would bring up every interface of the
# root as well, where the root has a network config of its own. Where seednet brought up the network from a
# NoCloud network-config, it has removed the catch-all already, and seednet-rootfs keeps it only for a root
# with no config at all. systemd-network-generator in the root writes what ip= says again by itself.
if [ ! -e /run/seednet/source ]; then
	rm -f /run/systemd/network/zzzz-dracut-default.network
fi
