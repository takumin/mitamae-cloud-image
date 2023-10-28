# frozen_string_literal: true

#
# Install Package
#

case node.platform
when 'debian', 'ubuntu'
  package 'wireguard'
when 'arch'
  package 'wireguard-tools'
else
  raise
end
