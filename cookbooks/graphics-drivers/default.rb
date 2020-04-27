# frozen_string_literal: true

#
# Check Platform
#

unless node[:platform].match(/^ubuntu$/)
  return
end

unless node[:target][:role].match(/nvidia/)
  return
end

#
# Constant Variables
#

NVIDIA_DRIVER_VERSION_AVAILABLE = [
  '390', # Old LTS
  '410',
  '415',
  '418',
  '430', # LTS
  '435',
  '440', # Latest
]

#
# Public Variables
#

node[:graphics_drivers]                  ||= Hashie::Mash.new
node[:graphics_drivers][:nvidia_version] ||= NVIDIA_DRIVER_VERSION_AVAILABLE.last

#
# Validate Variables
#

node.validate! do
  {
    graphics_drivers: {
      nvidia_version: match(/^(?:#{NVIDIA_DRIVER_VERSION_AVAILABLE.join('|')})$/),
    },
  }
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
# Apt Repository
#

apt_keyring 'Launchpad PPA for Graphics Drivers Team' do
  finger '2388FF3BE10A76F638F80723FCAE110B1118213C'
end

apt_repository 'Graphics Drivers Repository' do
  path '/etc/apt/sources.list.d/graphics-drivers.list'
  entry [
    {
      :default_uri => 'http://ppa.launchpad.net/graphics-drivers/ppa/ubuntu',
      :mirror_uri  => "#{ENV['APT_REPO_URL_PPA_GRAPHICS_DRIVERS']}",
      :suite       => '###platform_codename###',
      :components  => [
        'main',
      ],
    },
  ]
  notifies :run, 'execute[apt-get update]', :immediately
end

execute 'apt-get update' do
  action :nothing
end

#
# Install Package
#

package "nvidia-driver-#{node[:graphics_drivers][:nvidia_version]}"
