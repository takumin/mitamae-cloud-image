# frozen_string_literal: true

#
# Install Package
#

case node[:platform]
when 'debian', 'ubuntu'
  package 'wireguard'
when 'arch'
  if node[:target][:kernel].match(/lts/)
    package 'wireguard-lts'
  else
    package 'wireguard-dkms'
  end
  package 'wireguard-tools'
else
  raise
end
