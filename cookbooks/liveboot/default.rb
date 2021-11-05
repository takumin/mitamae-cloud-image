# frozen_string_literal: true

#
# Check Distribution
#

unless node[:target][:distribution].match(/^(debian|ubuntu)$/)
  return
end

#
# Package Install
#

package 'live-boot'

#
# Live Boot Disable Networking
#

# remote_file '/etc/initramfs-tools/scripts/init-top/liveboot-disable-networking' do
#   owner 'root'
#   group 'root'
#   mode  '0755'
# end

#
# Initramfs Configure Networking
#

# remote_file '/etc/initramfs-tools/scripts/init-top/initramfs-configure-networking' do
#   owner 'root'
#   group 'root'
#   mode  '0755'
# end

#
# Cloud-Init NoCloud Datasource Network Config
#

remote_file '/etc/initramfs-tools/scripts/init-bottom/cloud-init-nocloud-network-config' do
  owner 'root'
  group 'root'
  mode  '0755'
end

#
# Cloud-Init Disable Resize Rootfs
#

remote_file '/etc/initramfs-tools/scripts/init-bottom/cloud-init-disable-resize-rootfs' do
  owner 'root'
  group 'root'
  mode  '0755'
end

#
# Workaround: Removed netplan yaml file created in initramfs stage
# See also: https://askubuntu.com/questions/1228433/what-is-creating-run-netplan-eth0-yaml
#

remote_file '/etc/initramfs-tools/scripts/init-bottom/reset-network-interfaces' do
  owner 'root'
  group 'root'
  mode  '0755'
end
