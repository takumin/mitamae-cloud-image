# frozen_string_literal: true

#
# Select Packages
#

case node.target.kernel
when 'generic', 'virtual', 'lowlatency'
  node.linux_kernel.packages << "linux-image-#{node.target.kernel}"
when 'generic-hwe', 'virtual-hwe', 'lowlatency-hwe'
  node.linux_kernel.packages << "linux-image-#{node.target.kernel}-#{node.platform_version}"
when 'raspi'
  node.linux_kernel.packages << 'linux-image-raspi'
  node.linux_kernel.packages << 'linux-firmware-raspi'

  if node.platform_version == '22.04'
    node.linux_kernel.packages << 'linux-modules-extra-raspi'
  end
else
  raise
end

#
# Select Options
#

node.linux_kernel.options << '--no-install-recommends'
