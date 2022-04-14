# frozen_string_literal: true

#
# Create Initramfs
#

execute 'mkinitcpio -g /boot/initramfs-linux.img -k /boot/vmlinuz-linux -c /etc/mkinitcpio.conf -S autodetect' do
  only_if 'test -f /boot/initramfs-linux-fallback.img'
end

#
# Remove Initramfs Fallback
#

file '/boot/initramfs-linux-fallback.img' do
  action :delete
end

#
# Upgrade Packages
#

execute 'pacman -Syyu --noconfirm'

#
# Cleanup Packages
#

execute 'pacman -Scc --noconfirm'
