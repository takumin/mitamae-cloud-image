# frozen_string_literal: true

#
# Select Distribution
#

case node[:platform]
when 'debian', 'ubuntu'
  include_recipe 'debian.rb'
when 'arch'
  include_recipe 'arch.rb'
else
  raise
end

#
# Enabled Systemd Networkd
#

service 'systemd-networkd.service' do
  action :enable
  not_if 'systemctl is-enabled NetworkManager.service'
end

#
# Clear Machine ID File
#

file '/etc/machine-id' do
  owner   'root'
  group   'root'
  mode    '0444'
  content ''
end

link '/var/lib/dbus/machine-id' do
  to '/etc/machine-id'
  force true
end
