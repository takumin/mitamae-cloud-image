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
# Workaround: Fixed dependency to wait for Terminal
#

file '/lib/systemd/system/cloud-final.service' do
  action :edit
  not_if 'test "$(dpkg-query -f \'${Status}\' -W ubuntu-desktop)" = "install ok installed"'
  block do |content|
    DEPENDENCY = 'Before=getty@tty1.service'

    unless content.match(/^#{Regexp.escape(DEPENDENCY)}$/)
      content.gsub!(/^\[Unit\]$/, "[Unit]\n#{DEPENDENCY}")
    end
  end
end

#
# Workaround: Fixed dependency to wait for Network Manager
#

file '/lib/systemd/system/cloud-init.service' do
  action :edit
  only_if 'test "$(dpkg-query -f \'${Status}\' -W ubuntu-desktop)" = "install ok installed"'
  block do |content|
    DEPENDENCY = 'After=NetworkManager-wait-online.service'

    unless content.match(/^#{Regexp.escape(DEPENDENCY)}$/)
      content.gsub!(/^\[Unit\]$/, "[Unit]\n#{DEPENDENCY}")
    end

    content.gsub!(/^Before=sysinit\.target\n/, '')
  end
end

file '/lib/systemd/system/cloud-final.service' do
  action :edit
  only_if 'test "$(dpkg-query -f \'${Status}\' -W ubuntu-desktop)" = "install ok installed"'
  block do |content|
    DEPENDENCY = 'Before=display-manager.service'

    unless content.match(/^#{Regexp.escape(DEPENDENCY)}$/)
      content.gsub!(/^\[Unit\]$/, "[Unit]\n#{DEPENDENCY}")
    end
  end
end
