# frozen_string_literal: true

#
# Public Variables
#

node[:rootfs_archive]                    ||= Hashie::Mash.new
node[:rootfs_archive][:format]           ||= Hashie::Mash.new
node[:rootfs_archive][:target_dir]       ||= node[:target][:directory]

#
# Public Variables - Format Archive
#

case node[:target][:distribution]
when 'debian', 'ubuntu'
  unless %w{focal}.include?(node[:target][:suite])
    node[:rootfs_archive][:format][:tarball]  ||= 'zstd'
    node[:rootfs_archive][:format][:squashfs] ||= 'zstd'
  else
    node[:rootfs_archive][:format][:tarball]  ||= 'gzip'
    node[:rootfs_archive][:format][:squashfs] ||= 'gzip'
  end
when 'arch'
  node[:rootfs_archive][:format][:tarball]  ||= 'zstd'
  node[:rootfs_archive][:format][:squashfs] ||= 'zstd'
else
  raise
end

#
# Public Variables - Output Directory
#

case node[:target][:distribution]
when 'debian', 'ubuntu'
  node[:rootfs_archive][:output_dir] ||= File.join(
    'releases',
    node[:target][:distribution],
    node[:target][:suite],
    node[:target][:kernel],
    node[:target][:architecture],
    node[:target][:role],
  )
when 'arch'
  node[:rootfs_archive][:output_dir] ||= File.join(
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

if ENV['ROOTFS_ARCHIVE_FORMAT_TARBALL'].is_a?(String) and !ENV['ROOTFS_ARCHIVE_FORMAT_TARBALL'].empty?
  node[:rootfs_archive][:format][:tarball] = ENV['ROOTFS_ARCHIVE_FORMAT_TARBALL']
end

if ENV['ROOTFS_ARCHIVE_FORMAT_SQUASHFS'].is_a?(String) and !ENV['ROOTFS_ARCHIVE_FORMAT_SQUASHFS'].empty?
  node[:rootfs_archive][:format][:squashfs] = ENV['ROOTFS_ARCHIVE_FORMAT_SQUASHFS']
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

if node.target.architecture == 'amd64'
  execute 'extract-vmlinux vmlinuz > vmlinux' do
    cwd output_dir
    not_if 'test -f vmlinux'
  end
end

#
# SquashFS Archive
#

if ENV['DISABLE_SQUASHFS'] != 'true'
  execute "mksquashfs #{target_dir} rootfs.squashfs -comp #{node[:rootfs_archive][:format][:squashfs]}" do
    cwd output_dir
    not_if "test -f rootfs.squashfs"
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

  execute "tar -I #{cmd} -p --acls --xattrs --one-file-system -cf rootfs.tar.#{ext} -C #{target_dir} ." do
    cwd output_dir
    not_if "test -f rootfs.tar.#{ext}"
  end
end

#
# Diskimg Archive
#

if ENV['DISABLE_DISKIMG'] != 'true'
  if node.target.architecture == 'amd64'
    case node[:rootfs_archive][:format][:tarball]
    when 'gzip'
      cmd = 'pigz rootfs.ext4 > rootfs.ext4.gz'
      ext = 'gz'
    when 'lz4'
      cmd = 'lz4 rootfs.ext4 rootfs.ext4.lz4'
      ext = 'lz4'
    when 'xz'
      cmd = 'pixz rootfs.ext4 rootfs.ext4.xz'
      ext = 'xz'
    when 'zstd'
      cmd = 'zstd rootfs.ext4 -o rootfs.ext4.xz'
      ext = 'zstd'
    else
      raise
    end

    execute 'mkfs.ext4 rootfs.ext4' do
      command [
        'dd if=/dev/zero of=rootfs.ext4 bs=1M count=8192',
        'mkfs.ext4 rootfs.ext4',
      ].join(' && ')
      cwd output_dir
      not_if "test -f rootfs.ext4.#{ext}"
    end

    mount node[:rootfs_archive][:target_dir] do
      device "#{output_dir}/rootfs.ext4"
      not_if "test -f rootfs.ext4.#{ext}"
    end

    execute "tar -xf rootfs.tar.#{ext} -p --numeric-owner --acls --xattrs -C #{target_dir}" do
      cwd output_dir
      not_if "test -f rootfs.ext4.#{ext}"
    end

    mount node[:rootfs_archive][:target_dir] do
      action :absent
    end

    execute cmd do
      cwd output_dir
      not_if "test -f rootfs.ext4.#{ext}"
    end

    file "#{output_dir}/rootfs.ext4" do
      action :delete
    end

    file "#{output_dir}/firecracker.json" do
      content JSON.pretty_generate(Hashie::Mash.new({
        'boot-source': {
          'kernel_image_path': 'vmlinux',
          'boot_args': 'console=ttyS0 reboot=k panic=1 pci=off i8042.noaux',
          'initrd_path': 'initrd.img',
        },
        'drives': [
          {
            'drive_id': 'rootfs',
            'path_on_host': 'rootfs.ext4',
            'is_root_device': true,
            'is_read_only': false,
          },
        ],
        'machine-config': {
          'vcpu_count': 2,
          'mem_size_mib': 1024,
        },
      })).gsub(/:/, ': ')
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
  %w{
    bootcode.bin
    fixup.dat
    fixup_cd.dat
    fixup_db.dat
    fixup_x.dat
    fixup4.dat
    fixup4cd.dat
    fixup4db.dat
    fixup4x.dat
    start.elf
    start_cd.elf
    start_db.elf
    start_x.elf
    start4.elf
    start4cd.elf
    start4db.elf
    start4x.elf
  }.each do |bin|
    http_request "#{output_dir}/#{bin}" do
      url   "https://github.com/raspberrypi/firmware/raw/master/boot/#{bin}"
      owner 'root'
      group 'root'
      mode  '0644'
      # disable debug log
      sensitive true
    end
  end

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
      'boot=live',
      'ip=dhcp',
      'fetch=http://boot.internal/rpi/rootfs.squashfs',
      'ds=nocloud-net',
      'seednet=http://boot.internal/seed/#HOSTNAME#/default/',
    ].join(' ')
  end
end

#
# Raspberry Pi Ubuntu Firmware
#

case "#{node[:target][:distribution]}-#{node[:target][:kernel]}"
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
