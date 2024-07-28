# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match?(/(?:-nvidia|-nvidia-legacy)$/)
  return
end

#
# Check Architecture
#

unless node[:target][:architecture].match?(/(?:amd64)$/)
  MItamae.logger.error "nvidia: Unsupported architecture: #{node[:kernel][:machine]}"
  exit 1
end

#
# Check Platform
#

unless node[:platform].match?(/(?:debian|ubuntu)$/)
  MItamae.logger.error "nvidia: Unsupported platform: #{node[:platform]}"
  exit 1
end

#
# Required Packages
#

include_recipe File.expand_path('../../linux-headers', __FILE__)

#
# Install Package
#

case node[:platform]
when 'ubuntu'
  case node[:target][:role]
  when 'desktop-nvidia'
    package 'nvidia-driver-550'
  when 'desktop-nvidia-legacy'
    package 'nvidia-driver-470'
  when 'server-nvidia'
    package 'nvidia-headless-550-server'
  when 'server-nvidia-legacy'
    package 'nvidia-headless-470-server'
  else
    raise
  end
when 'debian'
  case node[:target][:role]
  when 'desktop-nvidia'
    package 'nvidia-driver'
  when 'desktop-nvidia-legacy'
    package 'nvidia-tesla-470-driver'
  when 'server-nvidia'
    package 'nvidia-driver' do
      options '--no-install-recommends'
    end
  when 'server-nvidia-legacy'
    package 'nvidia-tesla-470-driver' do
      options '--no-install-recommends'
    end
  else
    raise
  end
else
  raise
end
