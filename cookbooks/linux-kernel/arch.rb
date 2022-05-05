# frozen_string_literal: true

#
# Select Packages
#

node.linux_kernel.packages << node.target.kernel
node.linux_kernel.packages << 'linux-firmware'
