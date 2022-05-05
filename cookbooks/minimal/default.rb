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
  packages << 'libnss-systemd'
  packages << 'libpam-systemd'

  # networking
  packages << 'iproute2'
  packages << 'iputils-ping'
  packages << 'netbase'
  packages << 'netcat-openbsd'
end

#
# Install Packages
#

packages.each do |pkg|
  package pkg do
    options '--no-install-recommends'
  end
end
