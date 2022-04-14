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
# Workaround: Arch Linux: Kill GPG Agent
#

execute [
  "for pid in $(lsof +D #{node[:rootfs_umount][:target_dir]} 2>/dev/null | tail -n+2 | tr -s ' ' | cut -d ' ' -f 2 | sort -nu); do",
  "kill -KILL $pid;",
  "done",
].join(' ')


#
# Workaround: Arch Linux: https://bugs.archlinux.org/task/46169
#

node[:rootfs_umount][:umounts].unshift(node[:rootfs_umount][:target_dir])

#
# Unmount Target Directory
#

node[:rootfs_umount][:umounts].reverse.each do |v|
  mount v do
    action :absent
  end
end
