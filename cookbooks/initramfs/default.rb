# frozen_string_literal: true

#
# Public Variables
#

node[:initramfs]            ||= Hashie::Mash.new
node[:initramfs][:compress] ||= 'xz'

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
