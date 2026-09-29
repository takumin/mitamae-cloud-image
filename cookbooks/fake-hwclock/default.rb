# frozen_string_literal: true

#
# Check Kernel
#

unless node[:target][:kernel].eql?('raspberrypi')
  return
end

#
# Install Package
#

package 'fake-hwclock'
