# frozen_string_literal: true

#
# Required Packages
#

case "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}"
when /^ubuntu-(?:[0-9]+)\.(?:[0-9]+)-generic$/
  package 'linux-headers-generic'
when /^ubuntu-16\.04-generic-hwe$/
  package 'linux-headers-generic-hwe-16.04'
when /^ubuntu-18\.04-generic-hwe$/
  package 'linux-headers-generic-hwe-18.04'
when /^ubuntu-20\.04-generic-hwe$/
  package 'linux-headers-generic-hwe-20.04'
else
  MItamae.logger.error "Unknown platform: #{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}"
  exit 1
end

#
# Install Package
#

package 'wireguard'
