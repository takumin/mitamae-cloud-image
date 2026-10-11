#!/bin/sh
# vim: set noet :

command -v getarg > /dev/null || . /lib/dracut-lib.sh

cloud_init_nocloud_seednet() {(
	if [ ! -d "${NEWROOT}/etc/cloud/cloud.cfg.d" ]; then
		return
	fi

	datastore="$(getarg ds=)"
	seednet="$(getarg seednet=)"

	if [ -z "${datastore}" ] || [ -z "${seednet}" ]; then
		return
	fi

	case "${datastore%%;*}" in
		nocloud|nocloud-net)
			;;
		*)
			return
			;;
	esac

	# systemd-networkd sets no host name without systemd-hostnamed, which the initrd lacks, so read it from
	# the lease.
	hostname=
	domainname=
	for lease in /run/systemd/netif/leases/*; do
		[ -r "${lease}" ] || continue
		hostname="$(sed -n 's/^HOSTNAME=//p' "${lease}")"
		domainname="$(sed -n 's/^DOMAINNAME=//p' "${lease}")"
		[ -n "${hostname}" ] && break
	done

	if [ -z "${hostname}" ]; then
		read -r hostname < /proc/sys/kernel/hostname
		case "${hostname}" in
			'(none)'|localhost)
				hostname=
				;;
		esac
	fi

	case "${hostname}" in
		*.*)
			domainname="${domainname:-${hostname#*.}}"
			hostname="${hostname%%.*}"
			;;
	esac

	fqdn="${hostname}${domainname:+.${domainname}}"

	seednet="$(echo "${seednet}" | sed -E "s/#HOSTNAME#/${hostname}/; s/#DOMAINNAME#/${domainname}/; s/#FQDN#/${fqdn}/;")"

	# Cloud-Init before 24.1 keeps dsmode=local for an http(s) ds=nocloud;s= and skips the init modules,
	# so fetch the seed into the local seed directory instead.
	# The boot entries pass ds=nocloud;dsmode=net so that the init modules still run after the network is up.
	# TODO: Drop this script once Debian 12 is no longer supported and the boot entries use ds=nocloud;s= again.
	seeddir="${NEWROOT}/var/lib/cloud/seed/nocloud"
	mkdir -p "${seeddir}"

	for name in meta-data user-data vendor-data network-config; do
		if ! curl -fsS -o "${seeddir}/${name}" "${seednet%/}/${name}"; then
			rm -f "${seeddir}/${name}"
		fi
	done
)}

cloud_init_nocloud_seednet
