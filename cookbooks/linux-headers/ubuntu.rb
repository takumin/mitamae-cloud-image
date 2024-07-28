# frozen_string_literal: true

#
# Select Packages
#

case node.target.kernel
when 'generic', 'virtual', 'lowlatency'
  node.linux_headers.packages << "linux-headers-#{node.target.kernel}"
when 'generic-hwe', 'virtual-hwe', 'lowlatency-hwe'
  node.linux_headers.packages << "linux-headers-#{node.target.kernel}-#{node.platform_version}"
else
  raise
end

#
# Select Options
#

node.linux_headers.options << '--no-install-recommends'
