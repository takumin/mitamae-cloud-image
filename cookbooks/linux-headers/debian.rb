# frozen_string_literal: true

#
# Select Packages
#

case node.target.kernel
when 'generic', 'generic-backports'
  node.linux_headers.packages << "linux-headers-#{node.target.architecture}"
when 'cloud', 'cloud-backports'
  node.linux_headers.packages << "linux-headers-cloud-#{node.target.architecture}"
when 'rt', 'rt-backports'
  node.linux_headers.packages << "linux-headers-rt-#{node.target.architecture}"
else
  raise
end
