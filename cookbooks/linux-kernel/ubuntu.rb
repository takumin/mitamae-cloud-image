# frozen_string_literal: true

#
# Select Packages
#

case node.target.kernel
when 'generic', 'virtual'
  node.linux_kernel.packages << "linux-image-#{node.target.kernel}"
when 'generic-hwe', 'virtual-hwe'
  node.linux_kernel.packages << "linux-image-#{node.target.kernel}-#{node.platform_version}"
when 'raspi'
  node.linux_kernel.packages << 'linux-image-raspi'

  case node.platform_version
  when '18.04', '20.04'
    node.linux_kernel.packages << 'linux-firmware-raspi2'
  when '22.04'
    node.linux_kernel.packages << 'linux-modules-extra-raspi'
    node.linux_kernel.packages << 'linux-firmware-raspi'
  else
    raise
  end
else
  raise
end

#
# Select Options
#

node.linux_kernel.options << '--no-install-recommends'
