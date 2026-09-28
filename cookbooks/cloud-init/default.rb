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
# systemd-networkd (also netplan's default backend) leaves those interfaces unmanaged by
# NetworkManager, so they are missing from the GUI; cloud-init's own
# network-manager renderer drops netplan keys such as dhcp4-overrides, so
# render the config through netplan with the NetworkManager backend instead
if node[:target][:role].match?(/desktop/)
  file '/etc/cloud/cloud.cfg.d/90_network_renderer.cfg' do
    owner 'root'
    group 'root'
    mode  '0644'
    content [
      'system_info:',
      '  network:',
      "    renderers: ['netplan']",
      "    activators: ['netplan']",
      '',
    ].join("\n")
  end

  # The global renderer also applies to the definitions in the
  # 50-cloud-init.yaml written by cloud-init
  file '/etc/netplan/01-network-manager-all.yaml' do
    owner 'root'
    group 'root'
    mode  '0600'
    content [
      'network:',
      '  version: 2',
      '  renderer: NetworkManager',
      '',
    ].join("\n")
  end
end
