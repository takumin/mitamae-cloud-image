# frozen_string_literal: true

#
# Public Variables
#

node[:resolv_conf] ||= Hashie::Mash.new

#
# Public Variables - Target Directory
#

node[:resolv_conf][:target_dir] ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]

#
# Validate Variables
#

node.validate! do
  {
    resolv_conf: {
      target_dir: string,
    },
  }
end

#
# Private Variables
#

target_dir = node[:resolv_conf][:target_dir]

#
# Create Systemd Resolved Directory
#

directory File.join(target_dir, 'run', 'systemd', 'resolve') do
  owner 'root'
  group 'root'
  mode  '0755'
end

#
# Copy Host Systemd Resolved Stub Resolver
#

if File.exist?('/run/systemd/resolve/stub-resolv.conf')
  file File.join(target_dir, 'run', 'systemd', 'resolve', 'stub-resolv.conf') do
    owner   'root'
    group   'root'
    mode    '0644'
    content File.read('/run/systemd/resolve/stub-resolv.conf')
  end
else
  file File.join(target_dir, 'run', 'systemd', 'resolve', 'stub-resolv.conf') do
    owner   'root'
    group   'root'
    mode    '0644'
    content File.read('/etc/resolv.conf')
  end
end
