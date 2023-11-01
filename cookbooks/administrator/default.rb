# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match?(/(?:minimal|proxmox-ve)/)
  return
end

#
# Public Variables
#

node[:administrator] ||= Hashie::Mash.new

#
# Public Variables - User Name
#

node[:administrator][:username] ||= 'admin'

#
# Public Variables - Full Name
#

node[:administrator][:fullname] ||= 'Admin User'

#
# Public Variables - Password
#

node[:administrator][:password] ||= ''

#
# Public Variables - User Groups
#

node[:administrator][:groups] ||= [
  'adm',
  'audio',
  'cdrom',
  'dialout',
  'dip',
  'input',
  'plugdev',
  'render',
  'staff',
  'sudo',
  'tty',
  'users',
  'video',
]

#
# Public Variables - SSH Authorized Keys
#

node[:administrator][:ssh]                   ||= Hashie::Mash.new
node[:administrator][:ssh][:authorized_keys] ||= []

#
# Default Variables
#

if ENV['ADMIN_USERNAME'].is_a?(String) and !ENV['ADMIN_USERNAME'].empty?
  node[:administrator][:username] = ENV['ADMIN_USERNAME']
end

if ENV['ADMIN_FULLNAME'].is_a?(String) and !ENV['ADMIN_FULLNAME'].empty?
  node[:administrator][:fullname] = ENV['ADMIN_FULLNAME']
end

if ENV['ADMIN_PASSWORD'].is_a?(String) and !ENV['ADMIN_PASSWORD'].empty?
  node[:administrator][:password] = ENV['ADMIN_PASSWORD']
end

if ENV['ADMIN_SSH_AUTHORIZED_KEYS'].is_a?(String) and !ENV['ADMIN_SSH_AUTHORIZED_KEYS'].empty?
  node[:administrator][:ssh][:authorized_keys] = ENV['ADMIN_SSH_AUTHORIZED_KEYS'].split("\n")
end

#
# Validate Variables
#

node.validate! do
  {
    administrator: {
      username: match(/^(?:[A-Za-z0-9-_]+)$/),
      fullname: string,
      password: string,
      groups:   array_of(match(/^(?:[A-Za-z0-9-_]+)$/)),
      ssh: {
        authorized_keys: array_of(string),
      },
    },
  }
end

#
# Private Variables
#

authorized_keys = []

#
# Admin User
#

user node[:administrator][:username] do
  create_home true
  home        "/home/#{node[:administrator][:username]}"
  shell       '/bin/bash'

  unless node[:administrator][:password].empty?
    password node[:administrator][:password]
  end
end

#
# Join Groups
#

node[:group].keys.each do |k|
  next unless node[:administrator][:groups].include?(node[:group][k][:name])
  next if node[:group][k][:members].include?(node[:administrator][:username])

  execute "adduser #{node[:administrator][:username]} #{node[:group][k][:name]}"
end

#
# Import SSH Authorized Keys
#

node[:administrator][:ssh][:authorized_keys].each do |key|
  key.chomp.strip
  next if key.empty?

  authorized_keys << key
end

#
# Home Directory Permission
#

directory "/home/#{node[:administrator][:username]}" do
  owner node[:administrator][:username]
  group node[:administrator][:username]
  mode  '0755'
end

#
# SSH Directory Permission
#

directory "/home/#{node[:administrator][:username]}/.ssh" do
  owner node[:administrator][:username]
  group node[:administrator][:username]
  mode  '0700'
end

#
# Generate SSH Authorized Keys
#

file "/home/#{node[:administrator][:username]}/.ssh/authorized_keys" do
  owner node[:administrator][:username]
  group node[:administrator][:username]
  mode  '0644'
  content "#{authorized_keys.join("\n")}\n"
end
