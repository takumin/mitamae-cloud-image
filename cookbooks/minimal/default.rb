# frozen_string_literal: true

#
# Select Distribution
#

case node[:platform]
when 'debian'
  # init/systemd
  package 'init'
  package 'systemd-resolved'
  package 'systemd-oomd'
  # linux standard
  package 'lsb-release'
  # tuning
  package 'irqbalance'
when 'ubuntu'
  package 'ubuntu-minimal'
when 'arch'
  # TODO
else
  raise
end
