# frozen_string_literal: true

#
# Package Select
#

case node[:platform]

when 'debian'
  case "#{node[:platform_version]}-#{node[:target][:architecture]}-#{node[:target][:kernel]}"
  when /^(?:[0-9]+)\.?(?:[0-9]+)?-amd64-generic$/
    packages = %w{linux-image-amd64}
  when /^(?:[0-9]+)\.?(?:[0-9]+)?-arm64-generic$/
    packages = %w{linux-image-arm64}
  when /^(?:[0-9]+)\.?(?:[0-9]+)?-arm64-raspberrypi$/
    packages = %w{raspberrypi-bootloader raspberrypi-kernel}
  else
    MItamae.logger.error "linux-kernel: #{node[:platform]}: #{node[:platform_version]}-#{node[:target][:architecture]}-#{node[:target][:kernel]}"
    exit 1
  end

when 'ubuntu'
  case "#{node[:platform_version]}-#{node[:target][:architecture]}-#{node[:target][:kernel]}"
  when /^(?:[0-9]+)\.(?:[0-9]+)-arm64-raspi$/
    packages = %w{linux-image-raspi linux-firmware-raspi2}
  when /^(?:[0-9]+)\.(?:[0-9]+)-(?:amd64|arm64)-generic$/
    packages = %w{linux-image-generic}
  when /^16\.04-(?:amd64|arm64)-generic-hwe$/
    packages = %w{linux-image-generic-hwe-16.04}
  when /^18\.04-(?:amd64|arm64)-generic-hwe$/
    packages = %w{linux-image-generic-hwe-18.04}
  when /^20\.04-(?:amd64|arm64)-generic-hwe$/
    packages = %w{linux-image-generic-hwe-20.04}
  else
    MItamae.logger.error "linux-kernel: #{node[:platform]}: #{node[:platform_version]}-#{node[:target][:architecture]}-#{node[:target][:kernel]}"
    exit 1
  end

when 'arch'
  packages = %W{#{node[:target][:kernel]} linux-firmware}

else
  MItamae.logger.error "linux-kernel: unknown platform: #{node[:platform]}"
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
