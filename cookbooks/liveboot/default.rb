# frozen_string_literal: true

#
# Package Install
#

case node[:platform]
when 'debian', 'ubuntu'
  package 'live-boot'
else
  MItamae.logger.error "Unknown Platform: #{node[:platform]}"
  exit 1
end

#
# Workaround: Removed netplan yaml file created in initramfs stage
# See also: https://askubuntu.com/questions/1228433/what-is-creating-run-netplan-eth0-yaml
#

remote_file '/etc/initramfs-tools/scripts/init-bottom/reset-network-interfaces' do
  owner 'root'
  group 'root'
  mode  '0755'
  only_if 'test "$(dpkg-query -f \'${Status}\' -W ubuntu-desktop)" = "install ok installed"'
end
