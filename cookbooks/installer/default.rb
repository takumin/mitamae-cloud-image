# frozen_string_literal: true

#
# Check Target
#

# scripts/install-to-disk.sh installs the bare metal images from the live root onto a disk.
unless node[:target][:architecture].eql?('amd64') and node[:target][:kernel].match?(/^generic/)
  return
end

if node[:target][:role].match?(/minimal/)
  return
end

#
# Package Install
#

# diskform partitions with sfdisk and formats with mkfs, and the script extracts the root from the squashfs.
%w{fdisk dosfstools e2fsprogs xfsprogs btrfs-progs squashfs-tools}.each do |pkg|
  package pkg
end

# The postinst does nothing without an EFI system partition, so the live root only carries it for the install.
package 'systemd-boot'

#
# Kernel Install
#

# The kernel hook of dracut builds /boot/initrd.img-*, which kernel-install copies to the EFI system partition;
# without the mask its dracut plugin builds a second initrd, and the boot entry loads both.
directory '/etc/kernel/install.d' do
  owner 'root'
  group 'root'
  mode '0755'
end

link '/etc/kernel/install.d/50-dracut.install' do
  to '/dev/null'
end

#
# Kernel Hooks
#

# systemd-boot dropped its kernel hooks in 258 for the hook of initramfs-tools, which dracut never runs, so the
# kernel updates reach the EFI system partition only through these, with the initrd of the dracut hook.
file '/etc/kernel/postinst.d/zz-kernel-install' do
  owner 'root'
  group 'root'
  mode '0755'
  content <<~'__EOF__'
    #!/bin/sh

    set -e

    test -x /usr/bin/bootctl || exit 0

    bootctl is-installed --quiet || exit 0

    kernel-install add "$1" "$2" "/boot/initrd.img-$1"
  __EOF__
  not_if 'test -e /etc/kernel/postinst.d/zz-systemd-boot'
end

file '/etc/kernel/postrm.d/zz-kernel-install' do
  owner 'root'
  group 'root'
  mode '0755'
  content <<~'__EOF__'
    #!/bin/sh

    set -e

    test -x /usr/bin/bootctl || exit 0

    bootctl is-installed --quiet || exit 0

    kernel-install remove "$1"
  __EOF__
  not_if 'test -e /etc/kernel/postrm.d/zz-systemd-boot'
end
