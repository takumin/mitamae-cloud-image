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
  # required systemd-hostnamed
  package 'policykit-1'
  # linux standard
  package 'lsb-release'
  # tuning
  package 'irqbalance'
  # network
  package 'ethtool'
  package 'iproute2'
  package 'iputils-arping'
  package 'iputils-ping'
  package 'iputils-tracepath'
  package 'net-tools'
  package 'traceroute'
  # system
  package 'lsof'
  package 'pciutils'
  # utils
  package 'bash-completion'
  package 'less'
  package 'vim-tiny'
when 'arch'
  # TODO
else
  raise
end
