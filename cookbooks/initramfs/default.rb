# frozen_string_literal: true

#
# Package Install
#

case node[:platform]
when 'debian', 'ubuntu'
  package 'initramfs-tools'
when 'arch'
  package 'mkinitcpio'
else
  raise
end
