# frozen_string_literal: true

#
# Constant Variables
#

DATASOURCES_AVAILABLE = [
  'NoCloud',
  'ConfigDrive',
  'OpenNebula',
  'DigitalOcean',
  'Azure',
  'AltCloud',
  'OVF',
  'MAAS',
  'GCE',
  'OpenStack',
  'CloudSigma',
  'SmartOS',
  'Bigstep',
  'Scaleway',
  'AliYun',
  'Ec2',
  'CloudStack',
  'Hetzner',
  'IBMCloud',
  'Exoscale',
  'None',
]

#
# Public Variables
#

node[:cloud_init]               ||= Hashie::Mash.new
node[:cloud_init][:datasources] ||= ['NoCloud', 'None']

#
# Validate Variables
#

node.validate! do
  {
    cloud_init: {
      datasources: array_of(match(/^(?:#{DATASOURCES_AVAILABLE.join('|')})$/)),
    },
  }
end

#
# Package Config
#

debconf 'cloud-init' do
  question 'cloud-init/datasources'
  vtype    'multiselect'
  value    node[:cloud_init][:datasources].join(', ')
end

#
# Package Install
#

package 'cloud-init'

#
# Override Directory
#

%w{
  /etc/systemd/system/cloud-init.service.d
  /etc/systemd/system/cloud-config.service.d
  /etc/systemd/system/cloud-final.service.d
}.each do |d|
  directory d do
    owner 'root'
    group 'root'
    mode  '0755'
  end
end

#
# Workaround: https://github.com/canonical/cloud-init/pull/267
#

case "#{node[:platform]}-#{node[:platform_version]}"
when 'ubuntu-16.04', 'ubuntu-18.04'
  file '/etc/cloud/cloud.cfg' do
    action :edit
    not_if 'grep -E "renderers:" /etc/cloud/cloud.cfg'
    block do |content|
      if content.match(/^system_info:$/)
        content << "   # Workaround: https://github.com/canonical/cloud-init/pull/267\n"
        content << "   network:\n"
        content << "     renderers: ['netplan', 'eni']\n"
      end
    end
  end
end

#
# Workaround: Fixed dependency to wait for Network Manager
#

file '/etc/systemd/system/cloud-init.service.d/after_network_manager.conf' do
  owner   'root'
  group   'root'
  mode    '0644'
  content [
    '[Unit]',
    'After=NetworkManager-wait-online.service',
  ].join("\n")
  only_if 'test "$(dpkg-query -f \'${Status}\' -W ubuntu-desktop)" = "install ok installed"'
end

file '/lib/systemd/system/cloud-init.service' do
  action :edit
  block do |content|
    content.gsub!(/^Before=sysinit\.target\n/, '')
  end
  only_if 'test "$(dpkg-query -f \'${Status}\' -W ubuntu-desktop)" = "install ok installed"'
end

#
# Workaround: Fixed dependency to wait for systemd-resolved
#

file '/etc/systemd/system/cloud-init.service.d/after_systemd_resolved.conf' do
  owner   'root'
  group   'root'
  mode    '0644'
  content [
    '[Unit]',
    'After=systemd-resolved.service',
  ].join("\n")
  only_if 'test "$(dpkg-query -f \'${Status}\' -W ubuntu-desktop)" = "install ok installed"'
end

#
# Workaround: Fixed dependency to wait for Terminal
#

file '/etc/systemd/system/cloud-final.service.d/before_getty_terminal.conf' do
  not_if  'test "$(dpkg-query -f \'${Status}\' -W ubuntu-desktop)" = "install ok installed"'
  owner   'root'
  group   'root'
  mode    '0644'
  content [
    '[Unit]',
    'Before=getty@tty1.service',
  ].join("\n")
end

#
# Workaround: Fixed dependency to wait for Display Manager
#

file '/etc/systemd/system/cloud-final.service.d/before_display_manager.conf' do
  only_if 'test "$(dpkg-query -f \'${Status}\' -W ubuntu-desktop)" = "install ok installed"'
  owner   'root'
  group   'root'
  mode    '0644'
  content [
    '[Unit]',
    'Before=display-manager.service',
  ].join("\n")
end

file '/lib/systemd/system/cloud-final.service' do
  action :edit
  block do |content|
    content.gsub!(/^After=multi-user\.target\n/, '')
  end
  only_if 'test "$(dpkg-query -f \'${Status}\' -W ubuntu-desktop)" = "install ok installed"'
end
