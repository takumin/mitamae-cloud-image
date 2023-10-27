# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match?(/-nvidia$/)
  return
end

#
# Apt Repository
#

if node[:platform] == 'ubuntu'
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
end

#
# Required Packages
#

case "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}-#{node[:target][:role]}"
when /^ubuntu-(?:18|20|22)\.04-generic-(?:desktop|server)-nvidia/
  # nothing...
when /^ubuntu-18\.04-generic-hwe-(?:desktop|server)-nvidia/
  package 'linux-headers-generic-hwe-18.04'
  package 'xserver-xorg-hwe-18.04' if node[:target][:role] == 'desktop-nvidia'
when /^ubuntu-(?:20|22)\.04-generic-hwe-(?:desktop|server)-nvidia/
  package "linux-headers-generic-hwe-#{node[:platform_version]}"
else
  MItamae.logger.error "graphics-drivers: #{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}-#{node[:target][:role]}"
  exit 1
end

#
# Install Package
#

case "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:role]}"
when /^ubuntu-(?:18|20|22)\.04-desktop-nvidia$/
  package 'nvidia-driver-545'
when /^ubuntu-(?:18|20|22)\.04-desktop-nvidia-legacy$/
  package 'nvidia-driver-470'
when /^ubuntu-(?:18|20|22)\.04-server-nvidia$/
  package 'nvidia-headless-545-server'
when /^ubuntu-(?:18|20|22)\.04-server-nvidia-legacy$/
  package 'nvidia-driver-470-server'
else
  MItamae.logger.error "graphics-drivers: #{node[:platform]}-#{node[:platform_version]}-#{node[:target][:role]}"
  exit 1
end
