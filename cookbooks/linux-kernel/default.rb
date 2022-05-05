# frozen_string_literal: true

#
# Public Variables
#

node.reverse_merge!({
  linux_kernel: {
    packages: [],
    options:  [],
  },
})

#
# Select Distribution
#

include_recipe node.platform

#
# Validate Variables
#

node.validate! do
  {
    linux_kernel: {
      packages: array_of(string),
      options:  array_of(string),
    },
  }
end

#
# Package Install
#

node.linux_kernel.packages.each do |pkg|
  package pkg do
    options node.linux_kernel.options.join(' ')
  end
end
