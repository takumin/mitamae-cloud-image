# frozen_string_literal: true

#
# Public Variables
#

node[:hosts]            ||= Hashie::Mash.new
node[:hosts][:contents] ||= Hashie::Mash.new({
  '127.0.0.1': ['localhost.localdomain', 'localhost'],
  '::1':       ['ip6-localhost', 'ip6-loopback'],
  'fe00::0':   ['ip6-localnet'],
  'ff00::0':   ['ip6-mcastprefix'],
  'ff02::1':   ['ip6-allnodes'],
  'ff02::2':   ['ip6-allrouters'],
})

#
# Hostname File
#

file '/etc/hostname' do
  owner   'root'
  group   'root'
  mode    '0644'
  content 'localhost'
end

#
# Hosts File
#

contents = []
maxlen = node[:hosts][:contents].keys.map{|v| v.length}.max
node[:hosts][:contents].each do |k, v|
  contents << sprintf("%-#{maxlen}s %s", k, v.join(' '))
end

file '/etc/hosts' do
  owner   'root'
  group   'root'
  mode    '0644'
  content contents.join("\n")
end
