# frozen_string_literal: true

#
# Public Variables
#

node[:rootfs_archive]              ||= Hashie::Mash.new
node[:rootfs_archive][:target_dir] ||= node[:target][:directory]

#
# Public Variables - Format Archive
#

case node[:target][:distribution]
when 'debian', 'ubuntu', 'arch'
  node[:rootfs_archive][:format] ||= 'zstd'
else
  raise
end

case node.target.kernel
when 'raspberrypi', 'raspi'
  # NOTE: Debian Official Kernel Unsupported Zstd SquashFS
  node[:rootfs_archive][:format] = 'gzip'
end

#
# Public Variables - Output Directory
#

case node[:target][:distribution]
when 'debian', 'ubuntu'
  node[:rootfs_archive][:output_dir] ||= File.join(
    File.expand_path('../../..', __FILE__),
    'releases',
    node[:target][:distribution],
    node[:target][:suite],
    node[:target][:kernel],
    node[:target][:architecture],
    node[:target][:role],
  )
when 'arch'
  node[:rootfs_archive][:output_dir] ||= File.join(
    File.expand_path('../../..', __FILE__),
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
# Environment Variables
#

if ENV['ROOTFS_ARCHIVE_FORMAT'].is_a?(String) and !ENV['ROOTFS_ARCHIVE_FORMAT'].empty?
  node[:rootfs_archive][:format] = ENV['ROOTFS_ARCHIVE_FORMAT']
end

if ENV['TARGET_DIRECTORY'].is_a?(String) and !ENV['TARGET_DIRECTORY'].empty?
  node[:rootfs_archive][:target_dir] = ENV['TARGET_DIRECTORY']
end

if ENV['OUTPUT_DIRECTORY'].is_a?(String) and !ENV['OUTPUT_DIRECTORY'].empty?
  node[:rootfs_archive][:output_dir] = ENV['OUTPUT_DIRECTORY']
end

#
# Validate Variables
#

node.validate! do
  {
    rootfs_archive: {
      format:     match(/^(?:gzip|lz4|xz|zstd)$/),
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

case node[:rootfs_archive][:format]
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

#
# Output Directory
#

directory output_dir do
  owner 'root'
  group 'root'
  mode  '0755'
end

#
# Remove Old Files
#

execute "find #{output_dir} -mindepth 1 -maxdepth 1 -type f | xargs rm -f"

#
# Package Manifest
#

case node[:target][:distribution]
when 'debian', 'ubuntu'
  execute "chroot #{target_dir} dpkg -l | sed -E '1,5d' | awk '{print $2 \"\\t\" $3}' > packages.manifest" do
    cwd output_dir
    not_if "test -f packages.manifest"
  end
when 'arch'
  execute "chroot #{target_dir} pacman -Q > packages.manifest" do
    cwd output_dir
    not_if "test -f packages.manifest"
  end
else
  raise
end

#
# Kernel and Initramfs
#

files = {
  kernel: [],
  initrd: [],
}

%w{kernel vmlinuz}.each do |prefix|
  files[:kernel] << Dir.glob("#{target_dir}/boot/#{prefix}*")
end
%w{initrd initramfs}.each do |prefix|
  files[:initrd] << Dir.glob("#{target_dir}/boot/#{prefix}*")
end

[:kernel, :initrd].each do |sym|
  files[sym].flatten!
  files[sym].reject!{|f| File.symlink?(f) }
end

if files[:kernel].length != 1 or files[:initrd].length != 1
  raise "multiple files exist for kernel or initrd"
end

{
  kernel: 'vmlinuz',
  initrd: 'initrd.img',
}.each do |k, v|
  execute "cp #{files[k][0]} #{v}" do
    cwd output_dir
    not_if "test -f #{v}"
  end
end

#
# SquashFS Archive
#

if ENV['DISABLE_SQUASHFS'] != 'true'
  execute "mksquashfs #{target_dir} rootfs.squashfs -comp #{node[:rootfs_archive][:format]}" do
    cwd output_dir
    not_if "test -f rootfs.squashfs"
  end
end

#
# Tarball Archive
#

if ENV['DISABLE_TARBALL'] != 'true'
  case node[:rootfs_archive][:format]
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

  execute "tar -I #{cmd} -p --acls --xattrs --one-file-system -cf rootfs.tar.#{ext} -C #{target_dir} ." do
    cwd output_dir
    not_if "test -f rootfs.tar.#{ext}"
  end
end

#
# CPIO Archive
#

if ENV['DISABLE_CPIO'] != 'true'
  if node[:target][:role].match(/minimal/)
    case node[:rootfs_archive][:format]
    when 'gzip'
      cmd = 'pigz'
    when 'lz4'
      cmd = 'lz4'
    when 'xz'
      cmd = 'pixz'
    when 'zstd'
      cmd = 'zstd'
    else
      raise
    end

    execute "find . \\( -type f -o -type l \\) -a -not \\( -name 'vmlinuz*' -o -name 'initrd.img*' \\) -a -printf '%P\\n' | cpio -o | #{cmd} > #{output_dir}/rootfs.cpio.img" do
      cwd target_dir
      not_if "test -f rootfs.tar.#{ext}"
    end
  end
end

#
# Checksum Archive
#

if ENV['DISABLE_SHA256SUMS'] != 'true'
  execute "find . -mindepth 1 -maxdepth 1 -type f -not -name 'SHA256SUMS' -print0 | sed -E 's@./@@g' | sort -zn | xargs -0 sha256sum > SHA256SUMS" do
    cwd    output_dir
    not_if "test -f SHA256SUMS"
  end
end

#
# Raspberry Pi Common Firmware
#

case node[:target][:kernel]
when 'raspberrypi', 'raspi'
  file "#{output_dir}/config.txt" do
    content [
      'arm_64bit=1',
      'kernel=vmlinuz',
      'initramfs initrd.img followkernel',
      'force_turbo=1',
      'dtoverlay=miniuart-bt',
      'dtoverlay=vc4-kms-v3d-pi4',
      'disable_overscan=1',
      'max_framebuffers=2',
    ].join("\n")
  end

  file "#{output_dir}/cmdline.txt" do
    content [
      'console=ttyAMA0,115200',
      'console=tty1',
      'boot=live',
      'ip=dhcp',
      'fetch=http://boot.metal.internal/rpi/rootfs.squashfs',
      'ds=nocloud-net',
      'seednet=http://boot.metal.internal/seed/#HOSTNAME#/default/',
    ].join(' ')
  end
end

#
# Raspberry Pi Ubuntu Firmware
#

case "#{node[:target][:distribution]}-#{node[:target][:kernel]}"
when "debian-raspberrypi"
  %w{bin dat elf dtb}.each do |ext|
    execute "find '#{target_dir}/boot/firmware' -mindepth 1 -maxdepth 1 -name '*.#{ext}' -exec cp {} #{output_dir} \\;"
  end

  execute "cp -r #{target_dir}/boot/firmware/overlays #{output_dir}"
when "ubuntu-raspi"
  execute [
    "find '#{target_dir}/usr/lib/firmware' -mindepth 1 -maxdepth 1 -name '*-raspi'",
    "xargs -I {} find {}/device-tree/broadcom -type f",
    "xargs -I {} sh -c 'cp {} #{output_dir}/$(basename {})'",
  ].join(' | ')

  directory "#{output_dir}/overlays" do
    owner 'root'
    group 'root'
    mode  '0755'
  end

  execute [
    "find '#{target_dir}/usr/lib/firmware' -mindepth 1 -maxdepth 1 -name '*-raspi'",
    "xargs -I {} find {}/device-tree/overlays -type f",
    "xargs -I {} sh -c 'cp {} #{output_dir}/overlays/$(basename {})'",
  ].join(' | ')
end
