# frozen_string_literal: true

#
# Select Distribution
#

case node[:platform]
when 'debian', 'ubuntu'
  # init/systemd
  package 'init'
  package 'systemd-resolved'
  package 'systemd-oomd'
  # required systemd-hostnamed
  package 'polkitd'
  # linux standard
  package 'lsb-release'
  # tuning
  package 'irqbalance'
when 'arch'
  # TODO
else
  raise
end

#
# systemd-timesyncd speed up
#

file '/etc/systemd/timesyncd.conf' do
  action :edit
  block do |content|
    content.gsub!(/^#?ConnectionRetrySec=.*/, 'ConnectionRetrySec=1')
  end
end
