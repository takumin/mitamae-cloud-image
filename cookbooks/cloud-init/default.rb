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
