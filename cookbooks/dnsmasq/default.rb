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

#
# Service Configuration
#

file '/etc/dnsmasq.d/systemd-resolved' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<~__EOF__
  except-interface=lo
  bind-dynamic
  __EOF__
end
