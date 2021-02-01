#
# Public Variables
#

node[:rootfs_mount]              ||= Hashie::Mash.new
node[:rootfs_mount][:target_dir] ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]
node[:rootfs_mount][:mounts]     ||= [
  {
    :target  => File.join(node[:rootfs_mount][:target_dir], 'dev'),
    :device  => 'devtmpfs',
    :type    => 'devtmpfs',
  },
  {
    :target  => File.join(node[:rootfs_mount][:target_dir], 'dev', 'pts'),
    :device  => 'devpts',
    :type    => 'devpts',
    :options => ['gid=5', 'mode=620'],
  },
  {
    :target  => File.join(node[:rootfs_mount][:target_dir], 'proc'),
    :device  => 'proc',
    :type    => 'proc',
  },
  {
    :target  => File.join(node[:rootfs_mount][:target_dir], 'run'),
    :device  => 'tmpfs',
    :type    => 'tmpfs',
    :options => ['mode=755'],
  },
  {
    :target  => File.join(node[:rootfs_mount][:target_dir], 'sys'),
    :device  => 'sysfs',
    :type    => 'sysfs',
  },
  {
    :target  => File.join(node[:rootfs_mount][:target_dir], 'tmp'),
    :device  => 'tmpfs',
    :type    => 'tmpfs',
  },
]

#
# Workaround: Arch Linux: https://bugs.archlinux.org/task/46169
#

node[:rootfs_mount][:mounts].unshift({
  :target  => node[:rootfs_mount][:target_dir],
  :device  => node[:rootfs_mount][:target_dir],
  :options => ['bind'],
})

#
# Validate Variables
#

node.validate! do
  {
    rootfs_mount: {
      target_dir: string,
      mounts:     array_of({
        target:  string,
        device:  string,
        type:    optional(string),
        options: optional(array_of(string)),
      }),
    },
  }
end

#
# Mount Target Directory
#

node[:rootfs_mount][:mounts].each do |v|
  mount v[:target] do
    device  v[:device]
    type    v[:type]
    options v[:options]
  end
end

directory File.join(node[:rootfs_mount][:target_dir], 'dev', 'shm') do
  mode '1777'
end
