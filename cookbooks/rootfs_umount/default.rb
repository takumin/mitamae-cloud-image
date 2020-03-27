#
# Public Variables
#

node[:rootfs_umount]              ||= Hashie::Mash.new
node[:rootfs_umount][:target_dir] ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]

#
# Validate Variables
#

node.validate! do
  {
    rootfs_umount: {
      target_dir: string,
    },
  }
end

#
# Unmount Target Directory
#

%W{
  #{File.join(node[:rootfs_umount][:target_dir], 'tmp')}
  #{File.join(node[:rootfs_umount][:target_dir], 'sys')}
  #{File.join(node[:rootfs_umount][:target_dir], 'run')}
  #{File.join(node[:rootfs_umount][:target_dir], 'proc')}
  #{File.join(node[:rootfs_umount][:target_dir], 'dev', 'pts')}
  #{File.join(node[:rootfs_umount][:target_dir], 'dev')}
}.each do |k|
  mount k do
    action :absent
  end
end
