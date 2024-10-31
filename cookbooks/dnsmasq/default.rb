# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match?(/bootstrap/)
  return
end

#
# Required Packages
#

package 'dnsmasq'
