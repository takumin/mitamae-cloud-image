# frozen_string_literal: true

#
# Select Packages
#

case node.target.kernel
when 'generic'
  node.linux_kernel.packages << "linux-image-#{node.target.architecture}"
when 'virtual'
  node.linux_kernel.packages << "linux-image-cloud-#{node.target.architecture}"
when 'raspberrypi'
  node.linux_kernel.packages << 'raspberrypi-bootloader'
  node.linux_kernel.packages << 'raspberrypi-kernel'
else
  raise
end
