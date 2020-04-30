# frozen_string_literal: true

#
# Package Install
#

package 'initramfs-tools'
package 'cloud-initramfs-copymods'
package 'cloud-initramfs-dyn-netconf'
package 'cloud-initramfs-rooturl'

#
# Workaround: Removed netplan yaml file created in initramfs stage
# See also: https://askubuntu.com/questions/1228433/what-is-creating-run-netplan-eth0-yaml
#

remote_file '/etc/initramfs-tools/scripts/init-bottom/reset-network-interfaces' do
  owner 'root'
  group 'root'
  mode  '0755'
end
