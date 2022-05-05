# frozen_string_literal: true

#
# Select Packages
#

if node.target.kernel.match(/^(?:raspberrypi)$/)
  node.linux_kernel.packages << 'raspberrypi-bootloader'
  node.linux_kernel.packages << 'raspberrypi-kernel'
else
  node.linux_kernel.packages << "linux-image-#{node.target.architecture}"
end
