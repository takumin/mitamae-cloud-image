# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match(/minimal/)
  return
end

#
# Required Packages
#

case node[:platform].to_sym
when :debian, :ubuntu
  packages = []

  # init/systemd
  packages << 'init'
  packages << 'dbus'
  packages << 'dbus-user-session'
  packages << 'policykit-1'
  packages << 'systemd'
  packages << 'systemd-coredump'
  packages << 'systemd-timesyncd' unless %w{stretch buster bionic}.include?(node.target.suite)
  packages << 'libnss-myhostname'
  packages << 'libnss-resolve'
  packages << 'libnss-systemd'
  packages << 'libpam-systemd'
  packages << 'overlayroot' if node[:platform] == 'ubuntu'

  # timezone
  packages << 'tzdata'

  # networking
  packages << 'ethtool'
  packages << 'iproute2'
  packages << 'iputils-ping'
  packages << 'netbase'
  packages << 'netcat-openbsd'

  # tuning
  packages << 'irqbalance'

  # utils
  packages << 'bash-completion'
  packages << 'htop'
  packages << 'less'
  packages << 'lsb-release'
  packages << 'lsof'
  packages << 'patch'
  packages << 'sudo'
  packages << 'vim-tiny'
end

#
# Install Packages
#

packages.each do |pkg|
  package pkg do
    options '--no-install-recommends'
  end
end

#
# Enable Networking
#

service 'systemd-networkd.service' do
  action :enable
end
