# frozen_string_literal: true

#
# Check Role
#

if node[:target][:role].match?(/(?:minimal|proxmox-ve)/)
  return
end

#
# Constant Variables
#

# DATASOURCES_AVAILABLE = [
#   'NoCloud',
#   'ConfigDrive',
#   'OpenNebula',
#   'DigitalOcean',
#   'Azure',
#   'AltCloud',
#   'OVF',
#   'MAAS',
#   'GCE',
#   'OpenStack',
#   'CloudSigma',
#   'SmartOS',
#   'Bigstep',
#   'Scaleway',
#   'AliYun',
#   'Ec2',
#   'CloudStack',
#   'Hetzner',
#   'IBMCloud',
#   'Exoscale',
#   'None',
# ]

#
# Public Variables
#

# node[:cloud_init]               ||= Hashie::Mash.new
# node[:cloud_init][:datasources] ||= ['NoCloud', 'None']

#
# Validate Variables
#

# node.validate! do
#   {
#     cloud_init: {
#       datasources: array_of(match(/^(?:#{DATASOURCES_AVAILABLE.join('|')})$/)),
#     },
#   }
# end

#
# Package Config
#

# case node[:platform]
# when 'debian', 'ubuntu'
#   debconf 'cloud-init' do
#     question 'cloud-init/datasources'
#     vtype    'multiselect'
#     value    node[:cloud_init][:datasources].join(', ')
#   end
# end

#
# Package Install
#

package 'cloud-init'
package 'netplan.io' # require nocloud datasources

#
# Netplan File Permission
#

file '/etc/netplan/50-cloud-init.yaml' do
  owner 'root'
  group 'root'
  mode '0644'
end

#
# Package Config
#

# case node[:platform]
# when 'arch'
#   file '/etc/cloud/cloud.cfg.d/99_datasources.cfg' do
#     owner   'root'
#     group   'root'
#     mode    '0644'
#     content "datasource_list: [ #{node[:cloud_init][:datasources].join(', ')} ]\n"
#   end
# end

#
# Copy the file for overwriting
#

# %w{
#   cloud-init.service
#   cloud-init.target
#   cloud-final.service
# }.each do |f|
#   execute "cp /lib/systemd/system/#{f} /etc/systemd/system/#{f}" do
#     not_if "test -f /etc/systemd/system/#{f}"
#   end
# end

#
# Wait network online
#

# file '/etc/systemd/system/cloud-init.service' do
#   action :edit
#   block do |content|
#     content.gsub!(/^Before=sysinit\.target$/, 'After=sysinit.target')
#     content.gsub!(/^Before=systemd-user-sessions\.service\n/, '')
#
#     unless content.match(/^After=systemd-resolved\.service$/)
#       content.gsub!(/^\[Unit\]$/, "[Unit]\nAfter=systemd-resolved.service")
#     end
#
#     unless content.match(/^After=NetworkManager-wait-online\.service$/)
#       content.gsub!(/^\[Unit\]$/, "[Unit]\nAfter=NetworkManager-wait-online.service")
#     end
#   end
# end

# file '/etc/systemd/system/cloud-init.target' do
#   action :edit
#   block do |content|
#     content.gsub!(/^After=multi-user\.target$/, 'Before=multi-user.target')
#   end
# end

# file '/etc/systemd/system/cloud-final.service' do
#   action :edit
#   block do |content|
#     content.gsub!(/^After=multi-user\.target$/, 'Before=multi-user.target')
#
#     unless content.match(/^Before=systemd-user-sessions\.service$/)
#       content.gsub!(/^\[Unit\]$/, "[Unit]\nBefore=systemd-user-sessions.service")
#     end
#
#     if node.key?(:autologin)
#       node.autologin.keys.each do |k|
#         unless content.match(/^Before=#{node.autologin[k].service}@#{node.autologin[k].port}.service$/)
#           content.gsub!(/^\[Unit\]$/, "[Unit]\nBefore=#{node.autologin[k].service}@#{node.autologin[k].port}.service")
#         end
#       end
#     end
#
#     unless content.match(/^Before=display-manager\.service$/)
#       content.gsub!(/^\[Unit\]$/, "[Unit]\nBefore=display-manager.service")
#     end
#   end
# end
