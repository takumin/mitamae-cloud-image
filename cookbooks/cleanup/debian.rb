# frozen_string_literal: true

#
# Copy Initramfs File
#

case "#{node[:platform]}-#{node[:target][:kernel]}"
when "debian-raspberrypi"
  # Create Initramfs
  execute 'find /lib/modules -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | xargs -n1 -I {} sh -c "test ! -f /boot/initrd.img-{} && update-initramfs -c -k {} || true"'
else
  # Get Kernel Version
  GET_KERNEL_VERSION = "dpkg -l | awk '{print $2}' | grep -E '^linux-image-[0-9\.-_]' | sort | tail -n 1 | sed -E 's/^linux-image-//'"

  # Cleanup Initramfs
  execute 'update-initramfs -d -k all' do
    not_if "test -f \"/boot/initrd.img-$(#{GET_KERNEL_VERSION})\""
  end

  # Create Initramfs
  execute "update-initramfs -c -k \"$(#{GET_KERNEL_VERSION})\"" do
    not_if "test -f \"/boot/initrd.img-$(#{GET_KERNEL_VERSION})\""
  end
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
