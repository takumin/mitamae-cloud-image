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

target_dir       = node[:resolv_conf][:target_dir]
resolv_conf_path = File.join(target_dir, 'etc', 'resolv.conf')

#
# Remove Symbolic Link
#

file resolv_conf_path do
  action :delete
  only_if "test \"'#{resolv_conf_path}'\" != \"$(stat -c '%N' #{resolv_conf_path})\""
end

#
# Copy Host Machine File
#

file resolv_conf_path do
  owner   'root'
  group   'root'
  mode    '0644'
  content File.read('/etc/resolv.conf')
end
