# frozen_string_literal: true

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
