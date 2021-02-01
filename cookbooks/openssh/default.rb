# frozen_string_literal: true

#
# Package Install
#

case node[:platform]
when 'debian', 'ubuntu'
  package 'openssh-server'
when 'arch'
  package 'openssh'
else
  raise
end
