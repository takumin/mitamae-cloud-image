#
# Public Variables
#

node[:finalize]              ||= Hashie::Mash.new
node[:finalize][:target_dir] ||= ENV['TARGET_DIRECTORY'] || String.new
node[:finalize][:output_dir] ||= ENV['OUTPUT_DIRECTORY'] || String.new

#
# Default Variables
#

if node[:finalize][:target_dir].empty?
  node[:finalize][:target_dir] = node[:target][:directory]
end

if node[:finalize][:output_dir].empty?
  node[:finalize][:output_dir] = File.join(
    'releases',
    node[:target][:distribution],
    node[:target][:suite],
    node[:target][:profile],
    node[:target][:architecture],
  )
end

#
# Required Packages
#

package 'squashfs-tools'
package 'pixz'

#
# Output Directory
#

directory node[:finalize][:output_dir] do
  owner 'root'
  group 'root'
  mode  '0755'
end

#
# SquashFS Archive
#

execute "mksquashfs #{node[:finalize][:target_dir]} #{node[:finalize][:output_dir]}/rootfs.squashfs -comp xz" do
  not_if "test -f #{node[:finalize][:output_dir]}/rootfs.squashfs"
end

#
# Tarball Archive
#

execute "tar -I pixz -p --acls --xattrs --one-file-system -cf #{node[:finalize][:output_dir]}/rootfs.tar.xz -C #{node[:finalize][:target_dir]} ." do
  not_if "test -f #{node[:finalize][:output_dir]}/rootfs.tar.xz"
end

#
# File Permission
#

%W{
  #{node[:finalize][:output_dir]}/rootfs.squashfs
  #{node[:finalize][:output_dir]}/rootfs.tar.xz
}.each do |archive|
  file archive do
    owner 'root'
    group 'root'
    mode  '0644'
  end
end
