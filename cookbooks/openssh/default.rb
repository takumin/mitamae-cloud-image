# frozen_string_literal: true

#
# Package Install
#

case node[:platform]
when 'debian', 'ubuntu'
  if node[:target][:role].match(/minimal/)
    opts = '--no-install-recommends'
  else
    opts = ''
  end

  package 'openssh-server' do
    options opts
  end
when 'arch'
  package 'openssh'
else
  raise
end
