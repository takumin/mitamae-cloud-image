# frozen_string_literal: true

#
# Package Select
#

case "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}"
when /^ubuntu-(?:[0-9]+)\.(?:[0-9]+)-generic$/
  package = 'linux-image-generic'
when /^ubuntu-16\.04-generic-hwe$/
  package = 'linux-image-generic-hwe-16.04'
when /^ubuntu-18\.04-generic-hwe$/
  package = 'linux-image-generic-hwe-18.04'
else
  MItamae.logger.error "Unknown platform: #{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}"
  exit 1
end

#
# Package Install
#

case node[:platform]
when 'ubuntu'
  options = '--no-install-recommends'
end

package package do
  options options
end
