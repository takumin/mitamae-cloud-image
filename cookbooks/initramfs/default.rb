# frozen_string_literal: true

#
# Public Variables
#

node[:initramfs] ||= Hashie::Mash.new

#
# Public Variables - Compression Format
#

case node[:target][:distribution]
when 'debian', 'ubuntu', 'arch'
  node[:initramfs][:compress] ||= 'zstd'
else
  raise
end

#
# Environment Variables
#

if ENV['INITRAMFS_COMPRESS'].is_a?(String) and !ENV['INITRAMFS_COMPRESS'].empty?
  node[:initramfs][:compress] = ENV['INITRAMFS_COMPRESS']
end

#
# Validate Variables
#

node.validate! do
  {
    initramfs: {
      compress: match(/^(?:gzip|lz4|xz|zstd)$/),
    },
  }
end

#
# Package Install
#

case node[:platform]
when 'debian', 'ubuntu'
  package 'initramfs-tools'

  case node[:initramfs][:compress]
  when 'gzip'
    package 'pigz'
  when 'lz4'
    package 'liblz4-tool'
  when 'xz'
    package 'pixz'
  when 'zstd'
    package 'zstd'
  else
    raise
  end

  file '/etc/initramfs-tools/initramfs.conf' do
    action :edit
    block do |content|
      unless content.match(/^COMPRESS=#{node[:initramfs][:compress]}$/)
        content.gsub!(/^COMPRESS=.*/, "COMPRESS=#{node[:initramfs][:compress]}")
      end
    end
  end
when 'arch'
  package 'mkinitcpio'
else
  raise
end

#
# Cloud-Init NoCloud Datasource Network Config
#

remote_file '/etc/initramfs-tools/scripts/init-bottom/zzz-cloud-init-nocloud-network-config' do
  owner  'root'
  group  'root'
  mode   '0755'
  source 'files/cloud-init-nocloud-network-config'
end

#
# Live Boot Disable Cloud-Init Resize Rootfs
#

remote_file '/etc/initramfs-tools/scripts/init-bottom/zzz-liveboot-disable-cloud-init-resize-rootfs' do
  owner  'root'
  group  'root'
  mode   '0755'
  source 'files/liveboot-disable-cloud-init-resize-rootfs'
end

#
# Check Distribution
#

unless node[:target][:distribution].match(/^ubuntu$/)
  return
end

#
# Live Boot Disable Internal Networking
#

remote_file '/etc/initramfs-tools/scripts/init-top/zzz-liveboot-disable-internal-networking' do
  owner  'root'
  group  'root'
  mode   '0755'
  source 'files/liveboot-disable-internal-networking'
end

#
# Live Boot Enable Initramfs Networking
#

remote_file '/etc/initramfs-tools/scripts/init-top/zzz-liveboot-enable-initramfs-networking' do
  owner  'root'
  group  'root'
  mode   '0755'
  source 'files/liveboot-enable-initramfs-networking'
end

#
# Workaround: Removed netplan yaml file created in initramfs stage
# See also: https://askubuntu.com/questions/1228433/what-is-creating-run-netplan-eth0-yaml
#

remote_file '/etc/initramfs-tools/scripts/init-bottom/zzz-reset-network-interfaces' do
  owner  'root'
  group  'root'
  mode   '0755'
  source 'files/reset-network-interfaces'
end
