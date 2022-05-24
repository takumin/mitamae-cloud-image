# frozen_string_literal: true

#
# Public Variables
#

node[:rootfs_archive]                    ||= Hashie::Mash.new
node[:rootfs_archive][:enabled]          ||= Hashie::Mash.new
node[:rootfs_archive][:enabled][:desync] ||= false # Error: An error occurred (429) when calling the PutObject operation: Too Many Requests
node[:rootfs_archive][:enabled][:zsync]  ||= true
node[:rootfs_archive][:format]           ||= Hashie::Mash.new
node[:rootfs_archive][:target_dir]       ||= node[:target][:directory]

#
# Public Variables - Format Archive
#

case node[:target][:distribution]
when 'debian', 'ubuntu'
  unless %w{stretch buster bionic focal}.include?(node[:target][:suite])
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

if node[:rootfs_archive][:enabled][:desync]
  directory "#{output_dir}/desync.chunks" do
    owner 'root'
    group 'root'
    mode  '0755'
  end
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
    %w{vmlinuz initrd.img}.each do |f|
      execute "find '#{target_dir}/boot' -type f -name '#{f}-*' -exec cp {} #{f} \\;" do
        cwd output_dir
        not_if "test -f #{f}"
      end

      file "#{output_dir}/#{f}" do
        owner 'root'
        group 'root'
        mode  '0644'
      end

      execute "zsyncmake2 #{f}" do
        cwd output_dir
        not_if "test -f #{f}.zsync"
      end

      if node[:rootfs_archive][:enabled][:desync]
        execute "desync make -s desync.chunks #{f}.caibx #{f}" do
          cwd output_dir
          not_if "test -f #{f}.caibx"
        end
      end
    end
  end
when 'arch'
  %W{vmlinuz-#{node[:target][:kernel]} initramfs-#{node[:target][:kernel]}.img}.each do |f|
    execute "find '#{target_dir}/boot' -type f -name '#{f}' -exec cp {} #{f} \\;" do
      cwd output_dir
      not_if "test -f #{f}"
    end

    file "#{output_dir}/#{f}" do
      owner 'root'
      group 'root'
      mode  '0644'
    end

    execute "zsyncmake2 #{f}" do
      cwd output_dir
      not_if "test -f #{f}.zsync"
    end

    if node[:rootfs_archive][:enabled][:desync]
      execute "desync make -s desync.chunks #{f}.caibx #{f}" do
        cwd output_dir
        not_if "test -f #{f}.caibx"
      end
    end
  end
else
  raise
end

#
# SquashFS Archive
#

if ENV['DISABLE_SQUASHFS'] != 'true'
  execute "mksquashfs #{target_dir} rootfs.squashfs -comp #{node[:rootfs_archive][:format][:squashfs]}" do
    cwd output_dir
    not_if "test -f rootfs.squashfs"
  end

  file "#{output_dir}/rootfs.squashfs" do
    owner 'root'
    group 'root'
    mode  '0644'
  end

  execute "zsyncmake2 rootfs.squashfs" do
    cwd output_dir
    not_if "test -f rootfs.squashfs.zsync"
  end

  if node[:rootfs_archive][:enabled][:desync]
    execute "desync make -s desync.chunks rootfs.squashfs.caibx rootfs.squashfs" do
      cwd output_dir
      not_if "test -f rootfs.squashfs.caibx"
    end
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

  file "#{output_dir}/rootfs.tar.#{ext}" do
    owner 'root'
    group 'root'
    mode  '0644'
  end

  execute "zsyncmake2 rootfs.tar.#{ext}" do
    cwd output_dir
    not_if "test -f rootfs.tar.#{ext}.zsync"
  end

  if node[:rootfs_archive][:enabled][:desync]
    execute "desync make -s desync.chunks rootfs.tar.#{ext}.caibx rootfs.tar.#{ext}" do
      cwd output_dir
      not_if "test -f rootfs.tar.#{ext}.caibx"
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

  file "#{output_dir}/SHA256SUMS" do
    owner 'root'
    group 'root'
    mode  '0644'
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
    owner   'root'
    group   'root'
    mode    '0644'
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
    owner   'root'
    group   'root'
    mode    '0644'
    content [
      'console=ttyAMA0,115200',
      'boot=live',
      'ip=dhcp',
      'fetch=http://boot.internal/rpi/rootfs.squashfs',
      'overlayroot=tmpfs',
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
