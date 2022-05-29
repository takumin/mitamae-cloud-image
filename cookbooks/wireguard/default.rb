# frozen_string_literal: true

#
# Check Suite
#

unless node.target.suite.match?(/^(?:stretch|buster)$/)
  return
end

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
