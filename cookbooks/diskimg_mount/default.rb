# frozen_string_literal: true

#
# Check Kernel
#

if node[:target][:kernel].match(/^(?:raspberrypi|raspi)$/)
  return
end

#
# Public Variables
#

node[:diskimg_mount]              ||= Hashie::Mash.new
node[:diskimg_mount][:target_dir] ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]

#
# Validate Variables
#

node.validate! do
  {
    diskimg_mount: {
      target_dir: string,
    },
  }
end

#
# Private Variables
#

diskimg = "#{File.expand_path(node[:diskimg_mount][:target_dir])}.qcow2"

#
# Required Packages
#

package 'qemu-utils'
package 'gdisk'
package 'dosfstools'
package 'xfsprogs'

#
# Load Kernel Modules
#

execute 'modprobe nbd' do
  not_if 'test -e /dev/nbd0'
end

#
# Create Disk Image
#

execute "qemu-img create -q -f qcow2 #{diskimg} 8G" do
  not_if "test -f #{diskimg}"
end

#
# Connect Disk Image
#

execute "qemu-nbd -c /dev/nbd0 #{diskimg}" do
  command [
    "qemu-nbd -d /dev/nbd0",
    "qemu-nbd -c /dev/nbd0 #{diskimg}",
  ].join(' && ')
  only_if 'test "$(cat /sys/class/block/nbd0/size)" = "0"'
end

#
# Destroy MBR/GPT Partition Table
#

execute 'sgdisk -Z /dev/nbd0' do
  not_if 'partprobe -s | grep "/dev/nbd0: gpt partitions"'
end

#
# Create GPT Partition Table
#

execute 'sgdisk -o /dev/nbd0' do
  not_if 'partprobe -s | grep "/dev/nbd0: gpt partitions"'
end

#
# Create BIOS Boot Partition
#

execute 'sgdisk -a 1 -n 1::2047 -c 1:"VirtBios" -t 1:ef02 /dev/nbd0' do
  command [
    'sgdisk -a 1 -n 1::2047 -c 1:"VirtBios" -t 1:ef02 /dev/nbd0',
    'sgdisk -A 1:set:2 /dev/nbd0',
  ].join(' && ')
  not_if 'test -e /dev/disk/by-partlabel/VirtBios'
end

#
# Create EFI System Partition
#

execute 'sgdisk -n 2::+512M -c 2:"VirtEsp" -t 2:ef00 /dev/nbd0' do
  not_if 'test -e /dev/disk/by-partlabel/VirtEsp'
end

#
# Create RootFs Partition
#

execute 'sgdisk -n 3::-1 -c 3:"VirtRoot" -t 3:8300 /dev/nbd0' do
  not_if 'test -e /dev/disk/by-partlabel/VirtRoot'
end

#
# Format EFI System Partition
#

execute 'mkfs.vfat -F 32 -n "VirtEsp" /dev/nbd0p2' do
  not_if 'test -e /dev/disk/by-label/VirtEsp'
end

#
# Format Root File System Partition
#

execute 'mkfs.xfs -L "VirtRoot" /dev/nbd0p3' do
  not_if 'test -e /dev/disk/by-label/VirtRoot'
end

#
# Mount Root File System Partition
#

mount node[:diskimg_mount][:target_dir] do
  device '/dev/nbd0p3'
end

#
# Mount EFI System Partition
#

directory File.join(node[:diskimg_mount][:target_dir], 'boot') do
  owner 'root'
  group 'root'
  mode  '0755'
end

mount File.join(node[:diskimg_mount][:target_dir], 'boot') do
  device '/dev/nbd0p2'
end

#
# Extract Rootfs
#

cmd = [
  'tar',
  '-xf', File.join(node[:rootfs_archive][:output_dir], 'rootfs.tar.zstd'),
  '-C', node[:diskimg_mount][:target_dir],
]

execute cmd.join(' ') do
  not_if "test -x #{node[:diskimg_mount][:target_dir]}/usr/bin/apt-get"
end
