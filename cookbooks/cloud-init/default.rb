# frozen_string_literal: true

#
# Check Role
#

if node[:target][:role].match?(/(?:minimal|proxmox-ve)/)
  return
end

#
# Package Install
#

package 'cloud-init'
package 'netplan.io' # require nocloud datasources

#
# Distribution
#

# The Raspberry Pi OS build of cloud-init sets distro to raspberry-pi-os,
# whose add_user renames the uid 1000 user with userconf-pi instead of
# creating one, so no user or authorized_keys is created on these images
if node[:target][:kernel].match?(/^(?:raspberrypi|raspi)$/)
  file '/etc/cloud/cloud.cfg.d/90_distro.cfg' do
    owner 'root'
    group 'root'
    mode  '0644'
    content [
      'system_info:',
      "  distro: #{node[:platform]}",
      '',
    ].join("\n")
  end
end

#
# Network Renderer
#

# Desktop images manage every interface with NetworkManager, but network
# boot hands cloud-init a network config (the ip= DHCP lease from the
# initramfs or the NoCloud seed network-config), and rendering it through
# netplan or systemd-networkd leaves those interfaces unmanaged by
# NetworkManager, so they are missing from the GUI; render the config as
# NetworkManager connections instead
if node[:target][:role].match?(/desktop/)
  file '/etc/cloud/cloud.cfg.d/90_network_renderer.cfg' do
    owner 'root'
    group 'root'
    mode  '0644'
    content [
      'system_info:',
      '  network:',
      "    renderers: ['network-manager']",
      "    activators: ['network-manager']",
      '',
    ].join("\n")
  end
end
