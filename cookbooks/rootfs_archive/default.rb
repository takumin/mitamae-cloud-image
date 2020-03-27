#
# Public Variables
#

node[:finalize]              ||= Hashie::Mash.new
node[:finalize][:target_dir] ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]
node[:finalize][:output_dir] ||= ENV['OUTPUT_DIRECTORY'] || File.join(
  'releases',
  node[:target][:distribution],
  node[:target][:suite],
  node[:target][:profile],
  node[:target][:architecture],
)

#
# Private Variables
#

target_dir = node[:finalize][:target_dir]
output_dir = node[:finalize][:output_dir]

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

execute "mksquashfs #{target_dir} #{output_dir}/rootfs.squashfs -comp xz" do
  not_if "test -f #{output_dir}/rootfs.squashfs"
end

#
# Tarball Archive
#

execute "tar -I pixz -p --acls --xattrs --one-file-system -cf #{output_dir}/rootfs.tar.xz -C #{target_dir} ." do
  not_if "test -f #{output_dir}/rootfs.tar.xz"
end

#
# File Permission
#

%W{
  #{output_dir}/rootfs.squashfs
  #{output_dir}/rootfs.tar.xz
}.each do |archive|
  file archive do
    owner 'root'
    group 'root'
    mode  '0644'
  end
end
