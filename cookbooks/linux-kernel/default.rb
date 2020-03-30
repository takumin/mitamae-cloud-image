# frozen_string_literal: true

KERNEL_FLAVOUR = %w{
  generic
  virtual
  generic-latest
  virtual-latest
}

#
# Public Variables
#

node[:linux_kernel]           ||= Hashie::Mash.new
node[:linux_kernel][:flavour] ||= KERNEL_FLAVOUR[0]

#
# Validate Variables
#

node.validate! do
  {
    linux_kernel: {
      flavour: match(/^(?:#{KERNEL_FLAVOUR.join('|')})$/),
    },
  }
end

#
# Normalize Variables
#

case "#{node[:platform]}-#{node[:platform_version]}-#{node[:linux_kernel][:flavour]}"
when /^ubuntu-(?:[0-9]+)\.(?:[0-9]+)-generic$/
  node[:linux_kernel][:package] ||= 'linux-image-generic'
when /^ubuntu-16\.04-generic-latest$/
  node[:linux_kernel][:package] ||= 'linux-image-generic-hwe-16.04'
when /^ubuntu-18\.04-generic-latest$/
  node[:linux_kernel][:package] ||= 'linux-image-generic-hwe-18.04'
else
  MItamae.logger.error "Unknown platform: #{node[:platform]}-#{node[:platform_version]}-#{node[:linux_kernel][:flavour]}"
  exit 1
end

#
# Package Install
#

case node[:platform]
when :ubuntu
  options = '--no-install-recommends'
else
  options = ''
end

package node[:linux_kernel][:package] do
  options '--no-install-recommends'
end
