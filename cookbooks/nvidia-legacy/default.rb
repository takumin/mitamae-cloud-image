# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match?(/-nvidia-legacy$/)
  return
end

#
# Check Architecture
#

unless node[:target][:architecture].match?(/(?:amd64)$/)
  MItamae.logger.error "nvidia-legacy: Unsupported architecture: #{node[:kernel][:machine]}"
  exit 1
end

#
# Check Platform
#

unless node[:platform].match?(/(?:debian|ubuntu)$/)
  MItamae.logger.error "nvidia-legacy: Unsupported platform: #{node[:platform]}"
  exit 1
end

#
# Required Packages
#

include_recipe File.expand_path('../linux-headers', File.dirname(__FILE__))

#
# Debconf
#

# The postinst compares the new driver with the nvidia/nouveau module
# loaded on the build host (visible through /proc and lsmod in the chroot)
# and raises an error-type debconf message on mismatch, which is
# meaningless for an image; disable the check
if node[:platform].match?(/^debian$/)
  debconf 'nvidia-support' do
    question 'nvidia-support/check-running-module-version'
    vtype    'boolean'
    value    'false'
  end
end

#
# Install Package
#

case node[:platform]
when 'ubuntu'
  case node[:target][:role]
  when 'desktop-nvidia-legacy'
    package 'nvidia-driver-580'
  when 'server-nvidia-legacy'
    package 'nvidia-headless-580-server'
  else
    raise
  end
when 'debian'
  case node[:target][:role]
  when 'desktop-nvidia-legacy'
    package 'nvidia-driver'
  when 'server-nvidia-legacy'
    package 'nvidia-driver' do
      options '--no-install-recommends'
    end
  else
    raise
  end
else
  raise
end
