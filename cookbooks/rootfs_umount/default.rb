#
# Public Variables
#

node[:rootfs_umount]              ||= Hashie::Mash.new
node[:rootfs_umount][:target_dir] ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]
node[:rootfs_umount][:umounts]    ||= [
  File.join(node[:rootfs_umount][:target_dir], 'dev'),
  File.join(node[:rootfs_umount][:target_dir], 'dev', 'pts'),
  File.join(node[:rootfs_umount][:target_dir], 'proc'),
  File.join(node[:rootfs_umount][:target_dir], 'run'),
  File.join(node[:rootfs_umount][:target_dir], 'sys'),
  File.join(node[:rootfs_umount][:target_dir], 'tmp'),
]

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
# Workaround: Arch Linux: https://bugs.archlinux.org/task/46169
#

node[:rootfs_umount][:umounts].unshift(node[:rootfs_umount][:target_dir])

#
# Workaround: Arch Linux: Kill GPG Agent
#

execute "chroot #{node[:rootfs_umount][:target_dir]} pkill gpg-agent" do
  only_if "test \"$(chroot #{node[:rootfs_umount][:target_dir]} sh -c 'ps --no-headers -C gpg-agent | wc -l')\" = 1"
end

#
# Unmount Target Directory
#

node[:rootfs_umount][:umounts].reverse.each do |v|
  mount v do
    action :absent
  end
end
