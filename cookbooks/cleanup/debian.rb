# frozen_string_literal: true

#
# Get Kernel Version Command
#

GET_KERNEL_VERSION = "dpkg -l | awk '{print $2}' | grep -E '^linux-image-[0-9\.-_]' | sort | tail -n 1 | sed -E 's/^linux-image-//'"

#
# Cleanup Initramfs
#

execute 'find /boot -type f -name "initrd.img-*" | xargs rm -f'

#
# Create Initramfs
#

execute "update-initramfs -c -k \"$(#{GET_KERNEL_VERSION})\"" do
  not_if "test -f \"/boot/initrd.img-$(#{GET_KERNEL_VERSION})\""
end

#
# Remove Cdebootstrap Helper Package
#

package 'cdebootstrap-helper-rc.d' do
  action :remove
end

#
# Upgrade Packages
#

execute 'apt-get -y dist-upgrade'

#
# Cleanup Packages
#

execute 'apt-get -y autoremove --purge'
execute 'apt-get -y clean'

#
# Cleanup Apt Cache
#

execute 'rm -fr /var/lib/apt/lists' do
  only_if 'test "$(find /var/lib/apt/lists -mindepth 1 -maxdepth 1 -type f | wc -l)" -gt 1'
  notifies :create, 'directory[/var/lib/apt/lists]'
  notifies :create, 'file[/var/lib/apt/lists/lock]'
end

directory '/var/lib/apt/lists' do
  action :nothing
  owner 'root'
  group 'root'
  mode  '0755'
end

file '/var/lib/apt/lists/lock' do
  action :nothing
  owner 'root'
  group 'root'
  mode  '0640'
end

#
# Workaround: Remove Unused Kernel/Initramfs Files
#

execute 'rm -f /vmlinuz.old' do
  only_if 'test -f /vmlinuz.old'
end

execute 'rm -f /initrd.img.old' do
  only_if 'test -f /initrd.img.old'
end
