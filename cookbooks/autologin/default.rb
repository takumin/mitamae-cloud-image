# frozen_string_literal: true

#
# Public Variables
#

node[:autologin]            ||= Hashie::Mash.new
node[:autologin][:terminal] ||= 'tty1'

#
# Validate Variables
#

node.validate! do
  {
    autologin: {
      terminal: match(/^(?:tty[0-9])$/),
    },
  }
end

#
# Override Terminal Variable
#

if node[:target][:role].match(/desktop/)
  node[:autologin][:terminal] = 'tty2'
end

#
# Override Systemd Directory
#

directory "/etc/systemd/system/getty@#{node[:autologin][:terminal]}.service.d" do
  owner 'root'
  group 'root'
  mode  '0755'
end

#
# Override Systemd Service
#

file "/etc/systemd/system/getty@#{node[:autologin][:terminal]}.service.d/autologin.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
  content [
    '[Service]',
    'Type=idle',
    'ExecStart=',
    'ExecStart=-/sbin/agetty --autologin root --noclear %I linux',
  ].join("\n")
end

#
# Enable Systemd Service
#

service "getty@#{node[:autologin][:terminal]}.service" do
  action :enable
end
