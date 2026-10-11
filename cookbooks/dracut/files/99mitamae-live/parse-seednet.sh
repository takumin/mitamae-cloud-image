#!/bin/sh
# vim: set noet :

# seednet= needs the network in the initrd, even when the root is not fetched over it.
# The network modules read rd.neednet in their cmdline hooks, which run after this one.
if getarg seednet= > /dev/null; then
	echo 'rd.neednet=1' > /etc/cmdline.d/90-mitamae-live-seednet.conf
fi
