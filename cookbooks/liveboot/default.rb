# frozen_string_literal: true

#
# Package Install
#

case node[:platform]
when 'ubuntu'
  package 'cloud-initramfs-dyn-netconf'
  package 'cloud-initramfs-copymods'
  package 'cloud-initramfs-rooturl'
  package 'overlayroot'
when 'debian'
  package 'live-boot'
else
  MItamae.logger.error "Unknown Platform: #{node[:platform]}"
  exit 1
end
