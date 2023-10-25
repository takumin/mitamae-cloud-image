# frozen_string_literal: true

#
# Select Distribution
#

case node[:platform]
when 'debian', 'ubuntu'
  # init/systemd
  package 'init'
  package 'systemd-resolved' if node[:platform].match(/debian/)
  package 'systemd-oomd'
  # linux standard
  package 'lsb-release'
  # tuning
  package 'irqbalance'
when 'arch'
  # TODO
else
  raise
end
