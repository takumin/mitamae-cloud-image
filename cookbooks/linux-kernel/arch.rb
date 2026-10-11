# frozen_string_literal: true

#
# Select Packages
#

# The cleanup cookbook builds the initramfs with mkinitcpio
node.linux_kernel.packages << 'mkinitcpio'
node.linux_kernel.packages << node.target.kernel
node.linux_kernel.packages << 'linux-firmware'
