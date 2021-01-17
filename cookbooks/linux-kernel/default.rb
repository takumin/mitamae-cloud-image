# frozen_string_literal: true

#
# Package Select
#

case "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:architecture]}-#{node[:target][:kernel]}"
when /^debian-(?:[0-9]+)\.?(?:[0-9]+)?-amd64-generic$/
  packages = %w{linux-image-amd64}
when /^debian-(?:[0-9]+)\.?(?:[0-9]+)?-arm64-generic$/
  packages = %w{linux-image-arm64}
when /^debian-(?:[0-9]+)\.?(?:[0-9]+)?-arm64-raspberrypi$/
  packages = %w{raspberrypi-bootloader raspberrypi-kernel}

when /^ubuntu-(?:[0-9]+)\.(?:[0-9]+)-arm64-raspi$/
  packages = %w{linux-image-raspi}
when /^ubuntu-(?:[0-9]+)\.(?:[0-9]+)-(?:amd64|arm64)-generic$/
  packages = %w{linux-image-generic}
when /^ubuntu-16\.04-(?:amd64|arm64)-generic-hwe$/
  packages = %w{linux-image-generic-hwe-16.04}
when /^ubuntu-18\.04-(?:amd64|arm64)-generic-hwe$/
  packages = %w{linux-image-generic-hwe-18.04}
when /^ubuntu-20\.04-(?:amd64|arm64)-generic-hwe$/
  packages = %w{linux-image-generic-hwe-20.04}
else
  MItamae.logger.error "linux-kernel:  #{node[:platform]}-#{node[:platform_version]}-#{node[:target][:architecture]}-#{node[:target][:kernel]}"
  exit 1
end

#
# Package Install
#

case node[:platform]
when 'ubuntu'
  options = '--no-install-recommends'
end

packages.each do |pkg|
  package pkg do
    options options
  end
end
