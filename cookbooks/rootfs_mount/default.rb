#
# Public Variables
#

node[:rootfs_mount]              ||= Hashie::Mash.new
node[:rootfs_mount][:target_dir] ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]

#
# Validate Variables
#

node.validate! do
  {
    rootfs_mount: {
      target_dir: string,
    },
  }
end

#
# Mount Target Directory
#

{
  "#{File.join(node[:rootfs_mount][:target_dir], 'dev')}" => {
    :device  => 'devtmpfs',
    :type    => 'devtmpfs',
    :options => [],
  },
  "#{File.join(node[:rootfs_mount][:target_dir], 'dev', 'pts')}" => {
    :device  => 'devpts',
    :type    => 'devpts',
    :options => ['gid=5', 'mode=620'],
  },
  "#{File.join(node[:rootfs_mount][:target_dir], 'proc')}" => {
    :device  => 'proc',
    :type    => 'proc',
    :options => [],
  },
  "#{File.join(node[:rootfs_mount][:target_dir], 'run')}" => {
    :device  => 'tmpfs',
    :type    => 'tmpfs',
    :options => ['mode=755'],
  },
  "#{File.join(node[:rootfs_mount][:target_dir], 'sys')}" => {
    :device  => 'sysfs',
    :type    => 'sysfs',
    :options => [],
  },
  "#{File.join(node[:rootfs_mount][:target_dir], 'tmp')}" => {
    :device  => 'tmpfs',
    :type    => 'tmpfs',
    :options => [],
  },
}.each do |k, v|
  mount k do
    device  v[:device]
    type    v[:type]
    options v[:options]
  end
end

directory File.join(node[:rootfs_mount][:target_dir], 'dev', 'shm') do
  mode '1777'
end
