# frozen_string_literal: true

#
# Check Platform
#

unless node[:target][:role].match(/desktop/)
  return
end

#
# Required Packages
#

case "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}-#{node[:target][:role]}"
when /^ubuntu-(?:[0-9]+)\.(?:[0-9]+)-generic$/
  # nothing...
when /^ubuntu-16\.04-generic-hwe-server-nvidia$/
  package 'xserver-xorg-core-hwe-16.04'
  package 'xserver-xorg-input-all-hwe-16.04'
  package 'xserver-xorg-legacy-hwe-16.04'
when /^ubuntu-16\.04-generic-hwe-desktop-nvidia$/
  package 'xserver-xorg-hwe-16.04'
when /^ubuntu-18\.04-generic-hwe-server-nvidia$/
  package 'xserver-xorg-core-hwe-18.04'
  package 'xserver-xorg-input-all-hwe-18.04'
  package 'xserver-xorg-legacy-hwe-18.04'
when /^ubuntu-18\.04-generic-hwe-desktop-nvidia$/
  package 'xserver-xorg-hwe-18.04'
else
  MItamae.logger.error "Unknown platform: #{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}"
  exit 1
end

#
# Package Install
#

case node[:platform]
when 'ubuntu'
  package 'ubuntu-desktop'
end

case "#{node[:platform]}-#{node[:platform_version]}"
when 'ubuntu-18.04'
  # Workaround: Fix System Log Error Message
  package 'gir1.2-clutter-1.0'
  package 'gir1.2-clutter-gst-3.0'
  package 'gir1.2-gtkclutter-1.0'

  # Workaround: Manage all network interfaces with Network Manager
  file '/etc/NetworkManager/conf.d/10-globally-managed-devices.conf' do
    owner 'root'
    group 'root'
    mode  '0644'
  end

  # Workaround: Explicitly enable Network Manager for netplan
  file '/etc/netplan/01-network-manager-all.yaml' do
    owner 'root'
    group 'root'
    mode  '0644'
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
end
