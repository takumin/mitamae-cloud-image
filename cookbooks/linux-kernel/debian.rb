# frozen_string_literal: true

#
# Select Packages
#

case node.target.kernel
when 'generic', 'generic-backports'
  node.linux_kernel.packages << "linux-image-#{node.target.architecture}"
when 'cloud', 'cloud-backports'
  node.linux_kernel.packages << "linux-image-cloud-#{node.target.architecture}"
when 'rt', 'rt-backports'
  node.linux_kernel.packages << "linux-image-rt-#{node.target.architecture}"
when 'proxmox'
  if node.platform_version.to_i >= 12
    node.linux_kernel.packages << 'proxmox-default-kernel'
  else
    # proxmox-default-kernel package does not exist in bullseye
    node.linux_kernel.packages << 'pve-kernel-5.15'
  end
  node.linux_kernel.packages << 'proxmox-kernel-helper'
when 'raspberrypi'
  node.linux_kernel.packages << 'raspberrypi-bootloader'
  node.linux_kernel.packages << 'raspberrypi-kernel'
else
  raise
end
