# frozen_string_literal: true

%w{/vmlinuz.old initrd.img.old}.each do |old|
  file old do
    action :delete
  end
end

execute 'apt-get -y autoremove --purge'
execute 'apt-get -y clean'

file '/etc/machine-id' do
  owner   'root'
  group   'root'
  mode    '0644'
  content ''
end

link '/var/lib/dbus/machine-id' do
  to '/etc/machine-id'
  force true
end
