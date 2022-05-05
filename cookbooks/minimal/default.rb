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
  packages = %w{
    init
    dbus
    dbus-user-session
    policykit-1
    systemd
    libnss-systemd
    libpam-systemd
  }
end

#
# Install Packages
#

packages.each do |pkg|
  package pkg do
    options '--no-install-recommends'
  end
end
