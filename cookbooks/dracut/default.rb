# frozen_string_literal: true

#
# Check Distribution
#

unless node[:target][:distribution].match(/^(debian|ubuntu)$/)
  return
end

#
# Public Variables
#

node[:dracut] ||= Hashie::Mash.new

#
# Public Variables - Compression Format
#

node[:dracut][:compress] ||= 'zstd'

#
# Public Variables - Network Module
#

# dracut 060 in Ubuntu 24.04 has no hooks that bring up a live root over systemd-networkd, so it keeps the
# dhclient based network-legacy module.
if "#{node[:target][:distribution]}-#{node[:target][:suite]}".eql?('ubuntu-noble')
  node[:dracut][:network] ||= 'network-legacy'
else
  node[:dracut][:network] ||= 'systemd-networkd'
end

#
# Environment Variables
#

if ENV['DRACUT_COMPRESS'].is_a?(String) and !ENV['DRACUT_COMPRESS'].empty?
  node[:dracut][:compress] = ENV['DRACUT_COMPRESS']
end

#
# Validate Variables
#

node.validate! do
  {
    dracut: {
      compress: match(/^(?:gzip|lz4|xz|zstd)$/),
      network:  match(/^(?:systemd-networkd|network-legacy)$/),
    },
  }
end

#
# Private Variables
#

modules_dir = '/usr/lib/dracut/modules.d/99mitamae-live'

#
# Apt Preferences
#

# Every package that hard-depends on initramfs-tools would replace dracut silently, so refuse them instead.
file '/etc/apt/preferences.d/dracut' do
  owner   'root'
  group   'root'
  mode    '0644'
  content <<~__EOF__
    Package: initramfs-tools initramfs-tools-core live-boot live-boot-initramfs-tools
    Pin: version *
    Pin-Priority: -1
  __EOF__
end

# dracut 059 in Debian 12 has the same gap as Ubuntu 24.04, which the backported dracut fills.
if "#{node[:target][:distribution]}-#{node[:target][:suite]}".eql?('debian-bookworm')
  file '/etc/apt/preferences.d/dracut-backports' do
    owner   'root'
    group   'root'
    mode    '0644'
    content <<~__EOF__
      Package: dracut dracut-*
      Pin: release o=Debian Backports
      Pin-Priority: 500
    __EOF__
  end
end

#
# Package Install
#

# The recommends (lvm2, mdadm, cryptsetup and so on) add nothing to a live root.
%w{dracut dracut-network}.each do |pkg|
  package pkg do
    options '--no-install-recommends'
  end
end

# Newer dracut ships the live modules in dracut-core, which provides dracut-live instead.
package 'dracut-live' do
  options '--no-install-recommends'
  not_if "dpkg-query -W -f '${Provides}\\n' dracut-core | grep -qw dracut-live"
end

# The url-lib module fetches the live root and the NoCloud seed with curl.
package 'curl'

case node[:dracut][:network]
when 'network-legacy'
  package 'isc-dhcp-client'
when 'systemd-networkd'
  # The initrd resolves the host names in the URLs through systemd-resolved, since systemd-networkd writes
  # no resolv.conf; the minimal cookbook installs it for the root as well.
  package 'systemd-resolved'
else
  raise
end

case node[:dracut][:compress]
when 'gzip'
  package 'pigz'
when 'lz4'
  package 'lz4'
when 'xz'
  package 'xz-utils'
when 'zstd'
  package 'zstd'
else
  raise
end

#
# Dracut Module
#

directory modules_dir do
  owner 'root'
  group 'root'
  mode  '0755'
end

%w{
  module-setup.sh
  parse-seednet.sh
  cloud-init-nocloud-seednet.sh
  live-disable-resize-rootfs.sh
  live-network.sh
}.each do |name|
  remote_file "#{modules_dir}/#{name}" do
    owner  'root'
    group  'root'
    mode   '0755'
    source "files/99mitamae-live/#{name}"
  end
end

#
# Dracut Configuration
#

# The image boots on any machine and takes the root from the kernel command line, so nothing of the build
# host goes into the initrd.
omit_network = %w{connman network-legacy network-manager systemd-networkd} - [node[:dracut][:network]]
add_modules  = ['mitamae-live', node[:dracut][:network]]
add_modules << 'systemd-resolved' if node[:dracut][:network].eql?('systemd-networkd')

file '/etc/dracut.conf.d/90-mitamae-cloud-image.conf' do
  owner   'root'
  group   'root'
  mode    '0644'
  content <<~__EOF__
    hostonly="no"
    hostonly_cmdline="no"
    compress="#{node[:dracut][:compress]}"
    add_dracutmodules+=" #{add_modules.join(' ')} "
    omit_dracutmodules+=" #{omit_network.join(' ')} "
  __EOF__
end
