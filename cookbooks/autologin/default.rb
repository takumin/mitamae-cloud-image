# frozen_string_literal: true

#
# Disable automatic terminal login when in desktop role
#

if node[:target][:roles].any?{|v| v.match?(/desktop/)}
  return
end

#
# Public Variables
#

node[:autologin]           ||= Hashie::Mash.new
node[:autologin][:service] ||= 'getty'
node[:autologin][:getty]   ||= '/sbin/agetty'
node[:autologin][:user]    ||= 'root'
node[:autologin][:port]    ||= 'tty1'
node[:autologin][:term]    ||= 'linux'
node[:autologin][:baud]    ||= []
node[:autologin][:opts]    ||= ['--noclear']

#
# Validate Variables
#

node.validate! do
  {
    autologin: {
      service: match(/^(?:serial-)?getty$/),
      getty:   string,
      user:    match(/^(?:[a-zA-Z0-9]*)$/),
      port:    match(/^(?:tty[a-zA-Z0-9]+)$/),
      term:    string,
      baud:    array_of(integer),
      opts:    array_of(string),
    },
  }
end

#
# Check Enable Recipe
#

if node[:autologin][:user].empty?
  return
end

#
# Build Command Options
#

agetty_args = [
  '--autologin', node[:autologin][:user],
]

unless node[:autologin][:opts].empty?
  node[:autologin][:opts].each do |opt|
    agetty_args.push(opt)
  end
end

agetty_args.push('%I')

unless node[:autologin][:baud].empty?
  agetty_args.push(node[:autologin][:baud].map{|b| b.to_s}.join(','))
end

agetty_args.push(node[:autologin][:term])

#
# Override Systemd Directory
#

directory "/etc/systemd/system/#{node[:autologin][:service]}@#{node[:autologin][:port]}.service.d" do
  owner 'root'
  group 'root'
  mode  '0755'
end

#
# Override Systemd Service
#

file "/etc/systemd/system/#{node[:autologin][:service]}@#{node[:autologin][:port]}.service.d/autologin.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
  content [
    '[Service]',
    'Type=idle',
    'ExecStart=',
    "ExecStart=-#{node[:autologin][:getty]} #{agetty_args.join(' ')}",
  ].join("\n")
end

file "/etc/systemd/system/#{node[:autologin][:service]}@#{node[:autologin][:port]}.service.d/noclear.conf" do
  owner 'root'
  group 'root'
  mode  '0644'
  content [
    '[Service]',
    'TTYVTDisallocate=no',
  ].join("\n")
end

#
# Enable Systemd Service
#

service "#{node[:autologin][:service]}@#{node[:autologin][:port]}.service" do
  action :enable
end

#
# Remove Unused Terminal
#

if node[:autologin][:port] != 'tty1'
  service 'getty@tty1' do
    action :disable
  end
end
