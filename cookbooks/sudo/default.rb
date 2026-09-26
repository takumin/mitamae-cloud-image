# frozen_string_literal: true

#
# Package Install
#

package 'sudo'

#
# Sudoers No Password
#

file '/etc/sudoers.d/no_passwd' do
  owner 'root'
  group 'root'
  mode  '0440'
  content "%sudo ALL=(ALL:ALL) NOPASSWD: ALL\n"
end
