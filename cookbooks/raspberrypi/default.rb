# frozen_string_literal: true

#
# Check Distribution
#

unless node[:target][:distribution].match(/^(?:debian|ubuntu)$/)
  return
end

#
# Check Kernel
#

unless node[:target][:kernel].match(/^(?:raspberrypi|raspi)$/)
  return
end

#
# Select Distribution
#

include_recipe node.platform
