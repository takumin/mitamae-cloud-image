# frozen_string_literal: true

#
# Public Variables
#

node.reverse_merge!({
  linux_firmware: {
    packages: [],
    options:  [],
  },
})

#
# Select Distribution
#

case node.platform
when 'debian', 'ubuntu'
  include_recipe node.platform
when 'arch'
  # linux-kernel installs linux-firmware together with the kernel
else
  raise
end

#
# Validate Variables
#

node.validate! do
  {
    linux_firmware: {
      packages: array_of(string),
      options:  array_of(string),
    },
  }
end

#
# Package Install
#

node.linux_firmware.packages.each do |pkg|
  package pkg do
    options node.linux_firmware.options.join(' ')
  end
end
