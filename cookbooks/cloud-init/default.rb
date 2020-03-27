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
