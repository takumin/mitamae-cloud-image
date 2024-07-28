# frozen_string_literal: true

#
# Public Variables
#

node.reverse_merge!({
  linux_headers: {
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
    linux_headers: {
      packages: array_of(string),
      options:  array_of(string),
    },
  }
end

#
# Package Install
#

node.linux_headers.packages.each do |pkg|
  package pkg do
    options node.linux_headers.options.join(' ')
  end
end
