#
# Phase
#
node[:phase] = :provision
#
# Helpers
#
include_recipe File.expand_path('../../helpers/normalize', __FILE__)
include_recipe File.expand_path('../../helpers/validate', __FILE__)
#
# Recipes
#
include_recipe File.expand_path('../../cookbooks/apt', __FILE__)
include_recipe File.expand_path('../../cookbooks/pacman', __FILE__)
include_recipe File.expand_path('../../cookbooks/curl', __FILE__)
include_recipe File.expand_path('../../cookbooks/minimal', __FILE__)
include_recipe File.expand_path('../../cookbooks/common', __FILE__)
include_recipe File.expand_path('../../cookbooks/desktop', __FILE__)
include_recipe File.expand_path('../../cookbooks/ubuntu-ja', __FILE__)
include_recipe File.expand_path('../../cookbooks/debian-ja', __FILE__)
include_recipe File.expand_path('../../cookbooks/raspberrypi', __FILE__)
include_recipe File.expand_path('../../cookbooks/proxmox-ve', __FILE__)
include_recipe File.expand_path('../../cookbooks/linux-kernel', __FILE__)
include_recipe File.expand_path('../../cookbooks/linux-firmware', __FILE__)
include_recipe File.expand_path('../../cookbooks/initramfs', __FILE__)
include_recipe File.expand_path('../../cookbooks/liveboot', __FILE__)
include_recipe File.expand_path('../../cookbooks/persistent', __FILE__)
include_recipe File.expand_path('../../cookbooks/administrator', __FILE__)
include_recipe File.expand_path('../../cookbooks/cloud-init', __FILE__)
include_recipe File.expand_path('../../cookbooks/hostname', __FILE__)
include_recipe File.expand_path('../../cookbooks/timezone', __FILE__)
include_recipe File.expand_path('../../cookbooks/locale', __FILE__)
include_recipe File.expand_path('../../cookbooks/keyboard', __FILE__)
include_recipe File.expand_path('../../cookbooks/autologin', __FILE__)
include_recipe File.expand_path('../../cookbooks/sudo', __FILE__)
include_recipe File.expand_path('../../cookbooks/openssh', __FILE__)
include_recipe File.expand_path('../../cookbooks/fake-hwclock', __FILE__)
include_recipe File.expand_path('../../cookbooks/wireguard', __FILE__)
include_recipe File.expand_path('../../cookbooks/nvidia', __FILE__)
include_recipe File.expand_path('../../cookbooks/nvidia-cuda', __FILE__)
include_recipe File.expand_path('../../cookbooks/nvidia-vgpu', __FILE__)
include_recipe File.expand_path('../../cookbooks/rtl8852au', __FILE__)
include_recipe File.expand_path('../../cookbooks/powerdns', __FILE__)
include_recipe File.expand_path('../../cookbooks/kea', __FILE__)
include_recipe File.expand_path('../../cookbooks/cleanup', __FILE__)
