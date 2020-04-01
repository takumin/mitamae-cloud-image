# frozen_string_literal: true

#
# Public Variables
#

node[:rootfs_archive]              ||= Hashie::Mash.new
node[:rootfs_archive][:target_dir] ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]
node[:rootfs_archive][:output_dir] ||= ENV['OUTPUT_DIRECTORY'] || File.join(
  'releases',
  node[:target][:distribution],
  node[:target][:suite],
  node[:target][:profile],
  node[:target][:architecture],
)

#
# Private Variables
#

target_dir = node[:rootfs_archive][:target_dir]
output_dir = node[:rootfs_archive][:output_dir]

#
# Required Packages
#

package 'squashfs-tools'
package 'pixz'

#
# Output Directory
#

directory output_dir do
  owner 'root'
  group 'root'
  mode  '0755'
end

#
# Package Manifest
#

execute "chroot #{target_dir} dpkg -l | sed -E '1,5d' | awk '{print $2 \"\\t\" $3}' > #{output_dir}/packages.manifest" do
  not_if "test -f #{output_dir}/packages.manifest"
end

#
# SquashFS Archive
#

if ENV['DISABLE_SQUASHFS'] != 'true'
  execute "mksquashfs #{target_dir} #{output_dir}/rootfs.squashfs -comp xz" do
    not_if "test -f #{output_dir}/rootfs.squashfs"
  end

  file "#{output_dir}/rootfs.squashfs" do
    owner 'root'
    group 'root'
    mode  '0644'
  end
end

#
# Tarball Archive
#

if ENV['DISABLE_TARBALL'] != 'true'
  execute "tar -I pixz -p --acls --xattrs --one-file-system -cf #{output_dir}/rootfs.tar.xz -C #{target_dir} ." do
    not_if "test -f #{output_dir}/rootfs.tar.xz"
  end

  file "#{output_dir}/rootfs.tar.xz" do
    owner 'root'
    group 'root'
    mode  '0644'
  end
end

#
# Kernel and Initramfs
#

execute "find '#{target_dir}/boot' -type f -name 'vmlinuz-*' -exec cp {} #{output_dir}/vmlinuz \\;" do
  not_if "test -f #{output_dir}/vmlinuz"
end

execute "find '#{target_dir}/boot' -type f -name 'initrd.img-*' -exec cp {} #{output_dir}/initrd.img \\;" do
  not_if "test -f #{output_dir}/initrd.img"
end
