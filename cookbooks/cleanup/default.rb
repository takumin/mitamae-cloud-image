# frozen_string_literal: true

# Workaround
if File.exist?('/vmlinuz.old')
  execute 'rm -f /vmlinuz.old'
end
if File.exist?('/initrd.img.old')
  execute 'rm -f /initrd.img.old'
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

directory '/var/lib/apt/lists' do
  action :delete
end

directory '/var/lib/apt/lists' do
  owner 'root'
  group 'root'
  mode  '0755'
end

file '/var/lib/apt/lists/lock' do
  owner 'root'
  group 'root'
  mode  '0640'
end
