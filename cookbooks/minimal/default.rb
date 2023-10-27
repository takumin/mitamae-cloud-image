# frozen_string_literal: true

#
# Select Distribution
#

case node[:platform]
when 'debian', 'ubuntu'
  # init/systemd
  package 'init'
  if node[:platform].eql?('debian') and node[:platform_version].to_i >= 12
    package 'systemd-resolved'
    package 'systemd-oomd'
  elsif node[:platform].eql?('ubuntu') and node[:platform_version].to_i >= 22
    package 'systemd-oomd'
  end
  # linux standard
  package 'lsb-release'
  # tuning
  package 'irqbalance'
when 'arch'
  # TODO
else
  raise
end
