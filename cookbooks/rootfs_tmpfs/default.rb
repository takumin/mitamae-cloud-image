# frozen_string_literal: true

#
# Check Tmpfs
#

unless node[:target][:tmpfs]
  return
end

#
# Public Variables
#

node[:rootfs_tmpfs]              ||= Hashie::Mash.new
node[:rootfs_tmpfs][:target_dir] ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]
node[:rootfs_tmpfs][:size]       ||= ENV['TARGET_TMPFS_SIZE'] || ''

#
# Validate Variables
#

node.validate! do
  {
    rootfs_tmpfs: {
      target_dir: string,
      size:       match(/^(?:|\d+[kmgKMG%]?)$/),
    },
  }
end

#
# Private Variables
#

target_dir = node[:rootfs_tmpfs][:target_dir]

options = ['mode=755']
options << "size=#{node[:rootfs_tmpfs][:size]}" unless node[:rootfs_tmpfs][:size].empty?

#
# Mount Or Unmount Target Directory
#

case node[:phase]
when :initialize
  execute "mkdir -p #{target_dir}" do
    not_if "test -d #{target_dir}"
  end

  mount target_dir do
    device  'tmpfs'
    type    'tmpfs'
    options options
  end
when :finalize
  # the rootfs is gone with the tmpfs, so release the memory once archived
  mount target_dir do
    action :absent
  end
end
