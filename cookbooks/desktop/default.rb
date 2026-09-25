# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match(/desktop/)
  return
end

#
# Select Distribution
#

include_recipe node.platform

# Workaround: Manage all network interfaces with Network Manager
file '/etc/NetworkManager/conf.d/10-globally-managed-devices.conf' do
  owner   'root'
  group   'root'
  mode    '0644'
  only_if 'test -d /etc/NetworkManager/conf.d'
end

# Workaround: Explicitly enable Network Manager for netplan
file '/etc/netplan/01-network-manager-all.yaml' do
  owner   'root'
  group   'root'
  mode    '0600'
  only_if 'test -d /etc/netplan'
  content <<~__EOF__
  # Workaround: Explicitly enable Network Manager
  network:
    version: 2
    renderer: NetworkManager
  __EOF__
end

# Remove Example Desktop Entry
file '/etc/skel/examples.desktop' do
  action :delete
end
