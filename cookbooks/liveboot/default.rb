# frozen_string_literal: true

#
# Check Distribution
#

unless node[:target][:distribution].match(/^(debian|ubuntu)$/)
  return
end

#
# Package Install
#

package 'live-boot'
