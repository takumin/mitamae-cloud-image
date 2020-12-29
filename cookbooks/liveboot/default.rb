# frozen_string_literal: true

#
# Package Install
#

case node[:platform]
when 'debian', 'ubuntu'
  package 'live-boot'
else
  MItamae.logger.error "Unknown Platform: #{node[:platform]}"
  exit 1
end

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
