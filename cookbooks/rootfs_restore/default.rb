# frozen_string_literal: true

#
# Public Variables
#

node[:rootfs_restore]              ||= Hashie::Mash.new
node[:rootfs_restore][:target_dir] ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]

# Same as the output directory of the rootfs_archive cookbook
release_dir = [node[:target][:distribution]]
release_dir << node[:target][:suite] if node[:target][:distribution].match?(/^(?:debian|ubuntu)$/)
release_dir << node[:target][:kernel]
release_dir << node[:target][:architecture]
release_dir << node[:target][:role]

node[:rootfs_restore][:squashfs] ||= File.join(
  ENV['OUTPUT_DIRECTORY'] || File.join(File.expand_path('../../..', __FILE__), 'releases', *release_dir),
  'rootfs.squashfs',
)

#
# Validate Variables
#

node.validate! do
  {
    rootfs_restore: {
      target_dir: string,
      squashfs:   string,
    },
  }
end

#
# Private Variables
#

target_dir = node[:rootfs_restore][:target_dir]
squashfs   = node[:rootfs_restore][:squashfs]

#
# Check Previous Build
#

unless File.exist?(squashfs)
  return
end

#
# Required Packages
#

package 'squashfs-tools'

#
# Restore Previous Build
#

# The previous build skips the bootstrap, and only an empty target directory
# is restored, so an interrupted build continues from where it stopped
execute "unsquashfs -f -d #{target_dir} #{squashfs}" do
  not_if "test -n \"$(ls -A #{target_dir} 2>/dev/null)\""
end
