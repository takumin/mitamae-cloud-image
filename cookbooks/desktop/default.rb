# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:roles].any?{|v| v.match?(/desktop/)}
  return
end

#
# Required Packages
#

case "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}"
when 'ubuntu-16.04-generic-hwe'
  package 'xserver-xorg-hwe-16.04'
when 'ubuntu-18.04-generic-hwe'
  package 'xserver-xorg-hwe-18.04'
when 'ubuntu-20.04-generic-hwe'
  # 2020/12/28: X.org HWE package does not exist
end

#
# Package Install
#

case node[:platform]
when 'ubuntu'
  package 'ubuntu-desktop'
end

# Workaround: Fix System Log Error Message
if "#{node[:platform]}-#{node[:platform_version]}" == 'ubuntu-18.04'
  package 'gir1.2-clutter-1.0'
  package 'gir1.2-clutter-gst-3.0'
  package 'gir1.2-gtkclutter-1.0'
end

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
  mode    '0644'
  only_if 'test -d /etc/netplan'
  content [
    '# Workaround: Explicitly enable Network Manager',
    'network:',
    '  version: 2',
    '  renderer: NetworkManager',
  ].join("\n")
end

# Remove Example Desktop Entry
file '/etc/skel/examples.desktop' do
  action :delete
end
