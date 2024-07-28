# frozen_string_literal: true

#
# Check Role
#

unless node.target.role.match(/rtl8852au/)
  return
end

#
# Download Archive
#

execute 'curl -fsSLo /tmp/rtl8852au.tar.gz https://github.com/lwfinger/rtl8852au/archive/refs/heads/dwa-x1850.tar.gz' do
  not_if 'test -f /tmp/rtl8852au.tar.gz'
end

#
# Source Directory
#

directory '/usr/src/rtl8852au-1.15.0.1' do
  owner 'root'
  group 'root'
  mode  '0755'
end

#
# Extract Archive
#

execute 'tar -xf /tmp/rtl8852au.tar.gz -C /usr/src/rtl8852au-1.15.0.1 --strip-components=1' do
  not_if 'test -f /usr/src/rtl8852au-1.15.0.1/Makefile'
end

#
# Cleanup Archive
#

file '/tmp/rtl8852au.tar.gz' do
  action :delete
end

#
# Required Packages
#

include_recipe File.expand_path('../linux-headers', File.dirname(__FILE__))

package 'build-essential'
package 'dkms'

#
# Get Kernel Version
#

execute 'find /lib/modules -mindepth 1 -maxdepth 1 -printf "%f\n" > /tmp/kernel_version' do
  not_if 'test -f /tmp/kernel_version'
end

#
# Add DKMS Tree
#

execute 'dkms add .' do
  cwd '/usr/src/rtl8852au-1.15.0.1'
  not_if 'test -d /var/lib/dkms/rtl8852au'
end

#
# Build DKMS
#

execute 'dkms build rtl8852au -v 1.15.0.1 -k $(cat /tmp/kernel_version)' do
  cwd '/usr/src/rtl8852au-1.15.0.1'
end

#
# Install DKMS
#

execute 'dkms install rtl8852au -v 1.15.0.1 -k $(cat /tmp/kernel_version)' do
  cwd '/usr/src/rtl8852au-1.15.0.1'
end

#
# Cleanup Kernel Version
#

file '/tmp/kernel_version' do
  action :delete
end
