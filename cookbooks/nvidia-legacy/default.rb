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
# Install Driver
#

# Debian ships no driver newer than 550, whose DKMS module fails to build
# against the 7.x kernels in trixie-backports; install the 580 series,
# the last one supporting Pascal GPUs such as the GTX 1080, from the
# NVIDIA installer instead
if node[:platform].match?(/^debian$/) and node[:target][:suite].match?(/^trixie$/) and node[:target][:kernel].match?(/-backports$/)
  include_recipe 'installer'
else
  include_recipe 'package'
end

#
# Hardware Video Acceleration
#

if node[:target][:role].match?(/^desktop-/)
  package 'nvidia-vaapi-driver'
  package 'vainfo'
end
