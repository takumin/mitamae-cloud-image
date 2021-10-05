# frozen_string_literal: true

#
# Public Variables
#

node[:rootfs_archive]                     ||= Hashie::Mash.new
node[:rootfs_archive][:format]            ||= Hashie::Mash.new
node[:rootfs_archive][:format][:tarball]  ||= 'gzip'
node[:rootfs_archive][:format][:squashfs] ||= 'gzip'

#
# Public Variables - Target Directory
#

node[:rootfs_archive][:target_dir] ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]

#
# Public Variables - Output Directory
#

case node[:target][:distribution]
when 'debian', 'ubuntu'
  node[:rootfs_archive][:output_dir] ||= ENV['OUTPUT_DIRECTORY'] || File.join(
    'releases',
    node[:target][:distribution],
    node[:target][:suite],
    node[:target][:kernel],
    node[:target][:architecture],
    node[:target][:role],
  )
when 'arch'
  node[:rootfs_archive][:output_dir] ||= ENV['OUTPUT_DIRECTORY'] || File.join(
    'releases',
    node[:target][:distribution],
    node[:target][:kernel],
    node[:target][:architecture],
    node[:target][:role],
  )
else
  raise
end

#
# Validate Variables
#

node.validate! do
  {
    rootfs_archive: {
      format: {
        tarball:  match(/^(?:gzip|lz4|xz|zstd)$/),
        squashfs: match(/^(?:gzip|lz4|xz|zstd)$/),
      },
      target_dir: match(/^(?:[0-9a-zA-Z-_\/\.]+)$/),
      output_dir: match(/^(?:[0-9a-zA-Z-_\/\.]+)$/),
    },
  }
end

#
# Private Variables
#

target_dir = node[:rootfs_archive][:target_dir]
output_dir = node[:rootfs_archive][:output_dir]

#
# Required Packages
#

package 'squashfs-tools'
package 'tar'

[:tarball, :squashfs].each do |sym|
  case node[:rootfs_archive][:format][sym]
  when 'gzip'
    package 'pigz'
  when 'lz4'
    package 'liblz4-tool'
  when 'xz'
    package 'pixz'
  when 'zstd'
    package 'zstd'
  else
    raise
  end
end

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

case node[:target][:distribution]
when 'debian', 'ubuntu'
  execute "chroot #{target_dir} dpkg -l | sed -E '1,5d' | awk '{print $2 \"\\t\" $3}' > #{output_dir}/packages.manifest" do
    not_if "test -f #{output_dir}/packages.manifest"
  end
when 'arch'
  execute "chroot #{target_dir} pacman -Q > #{output_dir}/packages.manifest" do
    not_if "test -f #{output_dir}/packages.manifest"
  end
else
  raise
end

#
# Kernel and Initramfs
#

case node[:target][:distribution]
when 'debian', 'ubuntu'
  case "#{node[:target][:distribution]}-#{node[:target][:kernel]}"
  when "debian-raspberrypi"
    execute [
      "find '#{target_dir}/boot' -type f -name 'kernel*img' -exec basename {} \\;",
      "xargs -I {} -n1 sh -c 'test ! -f #{output_dir}/{} && cp #{target_dir}/boot/{} #{output_dir}/{} || true'",
    ].join(' | ')

    INITRD_NAME = 'echo {} | sed -E "s@-[0-9]+\.[0-9]+\.[0-9]+@@; s@\+\$@@;"'

    execute [
      "find '#{target_dir}/boot' -type f -name 'initrd.img-*' -exec basename {} \\;",
      "xargs -I {} -n1 sh -c 'test ! -f #{output_dir}/$(#{INITRD_NAME}) && cp #{target_dir}/boot/{} #{output_dir}/$(#{INITRD_NAME}) || true'",
    ].join(' | ')
  else
    %w{vmlinuz initrd.img config}.each do |f|
      execute "find '#{target_dir}/boot' -type f -name '#{f}-*' -exec cp {} #{output_dir}/#{f} \\;" do
        not_if "test -f #{output_dir}/#{f}"
      end

      file "#{output_dir}/#{f}" do
        owner 'root'
        group 'root'
        mode  '0644'
      end
    end
  end
when 'arch'
  %W{vmlinuz-#{node[:target][:kernel]} initramfs-#{node[:target][:kernel]}.img}.each do |f|
    execute "find '#{target_dir}/boot' -type f -name '#{f}' -exec cp {} #{output_dir}/#{f} \\;" do
      not_if "test -f #{output_dir}/#{f}"
    end

    file "#{output_dir}/#{f}" do
      owner 'root'
      group 'root'
      mode  '0644'
    end
  end
else
  raise
end

#
# SquashFS Archive
#

if ENV['DISABLE_SQUASHFS'] != 'true'
  execute "mksquashfs #{target_dir} #{output_dir}/rootfs.squashfs -comp #{node[:rootfs_archive][:format][:squashfs]}" do
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
  case node[:rootfs_archive][:format][:tarball]
  when 'gzip'
    cmd = 'pigz'
    ext = 'gz'
  when 'lz4'
    cmd = 'lz4'
    ext = 'lz4'
  when 'xz'
    cmd = 'pixz'
    ext = 'xz'
  when 'zstd'
    cmd = 'zstd'
    ext = 'zstd'
  else
    raise
  end

  execute "tar -I #{cmd} -p --acls --xattrs --one-file-system -cf #{output_dir}/rootfs.tar.#{ext} -C #{target_dir} ." do
    not_if "test -f #{output_dir}/rootfs.tar.xz"
  end

  file "#{output_dir}/rootfs.tar.#{ext}" do
    owner 'root'
    group 'root'
    mode  '0644'
  end
end

#
# Checksum Archive
#

if ENV['DISABLE_SHA256SUMS'] != 'true'
  execute "find . -type f -not -name 'SHA256SUMS' -print0 | sed -E 's@./@@g' | sort -zn | xargs -0 sha256sum > SHA256SUMS" do
    cwd    output_dir
    not_if "test -f SHA256SUMS"
  end

  file "#{output_dir}/SHA256SUMS" do
    owner 'root'
    group 'root'
    mode  '0644'
  end
end
