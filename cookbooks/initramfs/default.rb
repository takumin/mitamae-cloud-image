# frozen_string_literal: true

#
# Public Variables
#

node[:initramfs] ||= Hashie::Mash.new

#
# Public Variables - Compression Format
#

case node[:target][:distribution]
when 'debian', 'ubuntu'
  unless %w{buster bionic focal}.include?(node[:target][:suite])
    node[:initramfs][:compress] ||= 'zstd'
  else
    node[:initramfs][:compress] ||= 'gzip'
  end
when 'arch'
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
# Live Boot Disable Networking
#

# remote_file '/etc/initramfs-tools/scripts/init-top/zzz-liveboot-disable-networking' do
#   owner  'root'
#   group  'root'
#   mode   '0755'
#   source 'files/liveboot-disable-networking'
# end

#
# Initramfs Configure Networking
#

# remote_file '/etc/initramfs-tools/scripts/init-top/zzz-initramfs-configure-networking' do
#   owner  'root'
#   group  'root'
#   mode   '0755'
#   source 'files/initramfs-configure-networking'
# end

#
# Cloud-Init NoCloud Datasource Network Config
#

# remote_file '/etc/initramfs-tools/scripts/init-bottom/zzz-cloud-init-nocloud-network-config' do
#   owner  'root'
#   group  'root'
#   mode   '0755'
#   source 'files/cloud-init-nocloud-network-config'
# end

#
# Cloud-Init Disable Resize Rootfs
#

# remote_file '/etc/initramfs-tools/scripts/init-bottom/zzz-cloud-init-disable-resize-rootfs' do
#   owner  'root'
#   group  'root'
#   mode   '0755'
#   source 'files/cloud-init-disable-resize-rootfs'
# end

#
# Workaround: Removed netplan yaml file created in initramfs stage
# See also: https://askubuntu.com/questions/1228433/what-is-creating-run-netplan-eth0-yaml
#

# remote_file '/etc/initramfs-tools/scripts/init-bottom/zzz-reset-network-interfaces' do
#   owner  'root'
#   group  'root'
#   mode   '0755'
#   source 'files/reset-network-interfaces'
# end
