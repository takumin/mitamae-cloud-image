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

if node[:target][:kernel].eql?('raspberrypi')
  # The Raspberry Pi OS build of cloud-init sets distro to raspberry-pi-os,
  # whose add_user renames the uid 1000 user with userconf-pi instead of
  # creating one, so no user or authorized_keys is created on these images
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

  # The Raspberry Pi OS cloud.cfg also drops apt_pipelining and apt_configure
  # from the config stage, so the apt config in the user-data is ignored; a
  # module list replaces the whole list, so redeclare it with both restored
  # before ntp, which installs its package with the configured sources
  file '/etc/cloud/cloud.cfg.d/90_config_modules.cfg' do
    owner 'root'
    group 'root'
    mode  '0644'
    content [
      'cloud_config_modules:',
      '  - ssh_import_id',
      '  - keyboard',
      '  - locale',
      '  - apt_pipelining',
      '  - apt_configure',
      '  - ntp',
      '  - timezone',
      '  - raspberry_pi',
      '  - disable_ec2_metadata',
      '  - runcmd',
      '',
    ].join("\n")
  end
end

#
# Network Renderer
#

if node[:target][:role].match?(/desktop/)
  # Desktop images manage every interface with NetworkManager, but network
  # boot hands cloud-init a network config (the ip= DHCP lease from the
  # initramfs or the NoCloud seed network-config), and rendering it through
  # systemd-networkd (also netplan's default backend) leaves those interfaces unmanaged by
  # NetworkManager, so they are missing from the GUI; cloud-init's own
  # network-manager renderer drops netplan keys such as dhcp4-overrides, so
  # render the config through netplan with the NetworkManager backend instead
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
