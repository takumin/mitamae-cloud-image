# frozen_string_literal: true

#
# Select Packages
#

case node.target.kernel
when 'generic'
  node.linux_kernel.packages << "linux-image-#{node.target.architecture}"
when 'cloud'
  node.linux_kernel.packages << "linux-image-cloud-#{node.target.architecture}"
when 'rt'
  node.linux_kernel.packages << "linux-image-rt-#{node.target.architecture}"
when 'proxmox'
  node.linux_kernel.packages << 'proxmox-default-kernel'
  node.linux_kernel.packages << 'proxmox-kernel-helper'
when 'raspberrypi'
  node.linux_kernel.packages << 'raspberrypi-bootloader'
  node.linux_kernel.packages << 'raspberrypi-kernel'
else
  raise
end
