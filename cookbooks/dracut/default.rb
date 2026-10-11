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

# dracut 059 in Debian 12 and 060 in Ubuntu 24.04 have no hooks that bring up a live root over systemd-networkd,
# and 106 and 107 print "get_url_handler: command not found" from livenet on every boot, so every suite takes the
# same current dracut from the PPA.
file '/etc/apt/preferences.d/dracut-ng' do
  owner   'root'
  group   'root'
  mode    '0644'
  content <<~__EOF__
    Package: dracut dracut-*
    Pin: release o=takumi.tmfam.com
    Pin-Priority: 600
  __EOF__
end

# The previous build restored from its squashfs still has the pin to the backported dracut.
file '/etc/apt/preferences.d/dracut-backports' do
  action :delete
end

#
# Apt Keyring
#

directory '/etc/apt/keyrings' do
  owner 'root'
  group 'root'
  mode  '0755'
end

gpg_keyring '/etc/apt/keyrings/ppa-dracut-ng.asc' do
  fingerprint 'C40C435F426247AFCD899D6752B8A990FCB52DAB'
  user_id     'Takumi Takahashi <takumiiinn@gmail.com>'
  url         'https://takumi.tmfam.com/ppa-dracut-ng/public.gpg.asc'
  owner       'root'
  group       'root'
  mode        '0644'
end

#
# Apt Repository
#

apt_repository 'dracut-ng Repository' do
  path '/etc/apt/sources.list.d/ppa-dracut-ng.sources'
  entry [
    {
      :uri        => AptMirror.uri('https://takumi.tmfam.com/ppa-dracut-ng', ENV['APT_REPO_URL_PPA_DRACUT_NG']),
      :signed_by  => '/etc/apt/keyrings/ppa-dracut-ng.asc',
      :suite      => '###platform_codename###',
      :components => ['main'],
    },
  ]
  notifies :run, 'execute[apt-get update]', :immediately
end

execute 'apt-get update' do
  action :nothing
end

#
# Package Install
#

# The recommends (lvm2, mdadm, cryptsetup and so on) add nothing to a live root.
# The package resource leaves the dracut of the previous build restored from its squashfs as it is, so install the
# candidate from the PPA whenever the installed version differs.
dracut_packages = %w{dracut dracut-network}
dracut_current  = dracut_packages.map do |pkg|
  "test \"$(dpkg-query -W -f '${Version}' #{pkg} 2>/dev/null)\" = \"$(LC_ALL=C apt-cache policy #{pkg} | sed -n 's/^ *Candidate: //p')\""
end

execute "apt-get -y --no-install-recommends install #{dracut_packages.join(' ')}" do
  not_if dracut_current.join(' && ')
end

# The url-lib module fetches the live root and the NoCloud seed with curl.
package 'curl'

# The initrd resolves the host names in the URLs through systemd-resolved, since systemd-networkd writes no
# resolv.conf; the minimal cookbook installs it for the root as well.
package 'systemd-resolved'

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
# The NVIDIA drivers load from the root; with their GSP firmware the initrd grew from about 100M to 270M,
# which no longer fit the build tmpfs of the desktop-nvidia-legacy role.
file '/etc/dracut.conf.d/90-mitamae-cloud-image.conf' do
  owner   'root'
  group   'root'
  mode    '0644'
  content <<~__EOF__
    hostonly="no"
    hostonly_cmdline="no"
    compress="#{node[:dracut][:compress]}"
    add_dracutmodules+=" mitamae-live systemd-networkd systemd-resolved "
    omit_dracutmodules+=" connman network-manager "
    omit_drivers+=" nvidia.* "
  __EOF__
end
