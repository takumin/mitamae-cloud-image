# frozen_string_literal: true

#
# Check Kernel
#

unless node[:target][:kernel].match(/^(?:raspberrypi|raspi)$/)
  return
end

#
# Install Package
#

package 'fake-hwclock'
