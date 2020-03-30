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
# Create Link File
#

if File.symlink?(resolv_conf_path)
  resolv_symlink_path = File.expand_path(File.join(File.dirname(resolv_conf_path), File.readlink(resolv_conf_path)))

  if resolv_symlink_path.match(/^#{Regexp.escape(File.join(target_dir, 'run'))}/)
    directory File.dirname(resolv_symlink_path) do
      owner 'root'
      group 'root'
      mode  '0755'
    end

    execute "cp -L /etc/resolv.conf #{resolv_symlink_path}" do
      not_if "test -r #{resolv_symlink_path}"
    end
  end
end
