# frozen_string_literal: true

#
# Select Packages
#

case node.kernel
when 'raspi'
  node.linux_kernel.packages << 'linux-image-raspi'

  case node.platform_version
  when '18.04', '20.04'
    node.linux_kernel.packages << 'linux-firmware-raspi2'
  when '22.04'
    node.linux_kernel.packages << 'linux-firmware-raspi'
  else
    raise
  end
when 'generic-hwe'
  case node.platform_version
  when '18.04'
    node.linux_kernel.packages << 'linux-image-generic-hwe-18.04'
  when '20.04'
    node.linux_kernel.packages << 'linux-image-generic-hwe-20.04'
  when '22.04'
    # nothing...
  else
    raise
  end
else
  node.linux_kernel.packages << 'linux-image-generic'
end

#
# Select Options
#

node.linux_kernel.options << '--no-install-recommends'
