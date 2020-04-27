# frozen_string_literal: true

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

# Workaround
execute 'rm -f /vmlinuz.old' do
  only_if 'test -f /vmlinuz.old'
end
execute 'rm -f /initrd.img.old' do
  only_if 'test -f /initrd.img.old'
end

execute 'apt-get -y autoremove --purge'
execute 'apt-get -y clean'

file '/etc/machine-id' do
  owner   'root'
  group   'root'
  mode    '0644'
end

link '/var/lib/dbus/machine-id' do
  to '/etc/machine-id'
  force true
end

execute 'rm -fr /var/lib/apt/lists' do
  only_if 'test "$(find /var/lib/apt/lists -type f | wc -l)" != "1"'
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
