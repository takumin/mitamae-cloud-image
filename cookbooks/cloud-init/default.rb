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
# Workaround: Fixed dependency to wait for Network Manager
#

if node[:target][:role].match(/desktop/)
  file '/lib/systemd/system/cloud-init.service' do
    action :edit
    block do |content|
      AFTER_NM = 'After=NetworkManager-wait-online.service'
      AFTER_SN = 'After=systemd-networkd-wait-online.service'

      unless content.match(/^#{Regexp.escape(AFTER_NM)}$/)
        content.gsub!(/^#{Regexp.escape(AFTER_SN)}$/, "#{AFTER_SN}\n#{AFTER_NM}")
      end

      content.gsub!(/^Before=sysinit\.target\n/, '')
    end
  end

  file '/lib/systemd/system/cloud-final.service' do
    action :edit
    block do |content|
      BEFORE_DM = 'Before=display-manager.service'
      AFTER_MU  = 'After=multi-user.target'

      unless content.match(/^#{Regexp.escape(BEFORE_DM)}$/)
        content.gsub!(/^#{Regexp.escape(AFTER_MU)}$/, "#{AFTER_MU}\n#{BEFORE_DM}")
      end
    end
  end
end
