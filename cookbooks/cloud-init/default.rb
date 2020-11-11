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
# Workaround: Removed netplan yaml file created in initramfs stage
# See also: https://askubuntu.com/questions/1228433/what-is-creating-run-netplan-eth0-yaml
#

remote_file '/etc/initramfs-tools/scripts/init-bottom/reset-network-interfaces' do
  owner 'root'
  group 'root'
  mode  '0755'
  only_if 'test "$(dpkg-query -f \'${Status}\' -W ubuntu-desktop)" = "install ok installed"'
end

#
# Copy the file for overwriting
#

%w{
  cloud-init.service
  cloud-init.target
  cloud-final.service
}.each do |f|
  execute "cp /lib/systemd/system/#{f} /etc/systemd/system/#{f}" do
    not_if "test -f /etc/systemd/system/#{f}"
  end
end

#
# Wait network online
#

file '/etc/systemd/system/cloud-init.service' do
  action :edit
  block do |content|
    content.gsub!(/^Before=sysinit\.target$/, 'After=sysinit.target')
    content.gsub!(/^Before=systemd-user-sessions\.service\n/, '')

    unless content.match(/^After=systemd-resolved\.service$/)
      content.gsub!(/^\[Unit\]$/, "[Unit]\nAfter=systemd-resolved.service")
    end

    unless content.match(/^After=NetworkManager-wait-online\.service$/)
      content.gsub!(/^\[Unit\]$/, "[Unit]\nAfter=NetworkManager-wait-online.service")
    end
  end
end

file '/etc/systemd/system/cloud-init.target' do
  action :edit
  block do |content|
    content.gsub!(/^After=multi-user\.target$/, 'Before=multi-user.target')
  end
end

file '/etc/systemd/system/cloud-final.service' do
  action :edit
  block do |content|
    content.gsub!(/^After=multi-user\.target$/, 'Before=multi-user.target')

    unless content.match(/^Before=systemd-user-sessions\.service$/)
      content.gsub!(/^\[Unit\]$/, "[Unit]\nBefore=systemd-user-sessions.service")
    end

    unless content.match(/^Before=getty@tty1\.service$/)
      content.gsub!(/^\[Unit\]$/, "[Unit]\nBefore=getty@tty1.service")
    end

    unless content.match(/^Before=display-manager\.service$/)
      content.gsub!(/^\[Unit\]$/, "[Unit]\nBefore=display-manager.service")
    end
  end
end
