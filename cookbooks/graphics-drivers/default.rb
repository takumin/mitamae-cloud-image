# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match(/nvidia/)
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
when /^ubuntu-(?:16|18|20)\.04-generic-(?:desktop|server)-nvidia$/
  # nothing...
when 'ubuntu-16.04-generic-hwe-desktop-nvidia'
  package 'xserver-xorg-hwe-16.04'
when 'ubuntu-16.04-generic-hwe-server-nvidia'
  package 'xserver-xorg-legacy-hwe-16.04'
when 'ubuntu-18.04-generic-hwe-desktop-nvidia'
  package 'linux-headers-generic-hwe-18.04'
  package 'xserver-xorg-hwe-18.04'
when 'ubuntu-18.04-generic-hwe-server-nvidia'
  package 'linux-headers-generic-hwe-18.04'
when /^ubuntu-20\.04-generic-hwe-(?:desktop|server)-nvidia$/
  package 'linux-headers-generic-hwe-20.04'
else
  MItamae.logger.error "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}-#{node[:target][:role]}"
  exit 1
end

#
# Install Package
#

case "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:role]}"
when 'ubuntu-16.04-desktop-nvidia'
  package 'nvidia-430'
when 'ubuntu-16.04-server-nvidia'
  package 'nvidia-430' do
    options '--no-install-recommends'
  end
when /^ubuntu-(?:18\.04|20\.04)-desktop-nvidia$/
  package 'nvidia-driver-470'
when /^ubuntu-(?:18\.04|20\.04)-server-nvidia$/
  package 'nvidia-headless-470-server'
else
  MItamae.logger.error "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:role]}"
  exit 1
end
