# frozen_string_literal: true

#
# Check Distribution
#

unless node[:target][:distribution].match(/^(arch)$/)
  return
end

#
# Public Variables
#

node[:archbootstrap] ||= Hashie::Mash.new

#
# Public Variables - Mirror
#

node[:archbootstrap][:mirror]           ||= Hashie::Mash.new
node[:archbootstrap][:mirror][:keyring] ||= 'hkp://p80.pool.sks-keyservers.net:80'
node[:archbootstrap][:mirror][:pacman]  ||= 'https://mirror.rackspace.com/archlinux/'

#
# Public Variables - Directory
#

node[:archbootstrap][:directory]                    ||= Hashie::Mash.new
node[:archbootstrap][:directory][:download]         ||= Hashie::Mash.new
node[:archbootstrap][:directory][:download][:path]  ||= '/tmp/archbootstrap'
node[:archbootstrap][:directory][:download][:owner] ||= 'root'
node[:archbootstrap][:directory][:download][:group] ||= 'root'
node[:archbootstrap][:directory][:download][:mode]  ||= '0755'
node[:archbootstrap][:directory][:extract]          ||= Hashie::Mash.new
node[:archbootstrap][:directory][:extract][:path]   ||= '/tmp/archbootstrap/root'
node[:archbootstrap][:directory][:extract][:owner]  ||= 'root'
node[:archbootstrap][:directory][:extract][:group]  ||= 'root'
node[:archbootstrap][:directory][:extract][:mode]   ||= '0755'
node[:archbootstrap][:directory][:target]           ||= Hashie::Mash.new
node[:archbootstrap][:directory][:target][:path]    ||= node[:target][:directory]
node[:archbootstrap][:directory][:target][:owner]   ||= 'root'
node[:archbootstrap][:directory][:target][:group]   ||= 'root'
node[:archbootstrap][:directory][:target][:mode]    ||= '0755'

#
# Public Variables - Directory
#

node[:archbootstrap][:filename]                    ||= Hashie::Mash.new
node[:archbootstrap][:filename][:squashfs]         ||= Hashie::Mash.new
node[:archbootstrap][:filename][:squashfs][:name]  ||= 'airootfs.sfs'
node[:archbootstrap][:filename][:squashfs][:owner] ||= 'root'
node[:archbootstrap][:filename][:squashfs][:group] ||= 'root'
node[:archbootstrap][:filename][:squashfs][:mode]  ||= '0644'
node[:archbootstrap][:filename][:checksum]         ||= Hashie::Mash.new
node[:archbootstrap][:filename][:checksum][:name]  ||= 'airootfs.sha512'
node[:archbootstrap][:filename][:checksum][:owner] ||= 'root'
node[:archbootstrap][:filename][:checksum][:group] ||= 'root'
node[:archbootstrap][:filename][:checksum][:mode]  ||= '0644'

#
# Default Variables
#

if ENV['ARCH_KEYRING_MIRROR'].is_a?(String) and !ENV['ARCH_KEYRING_MIRROR'].empty?
  node[:archbootstrap][:mirror][:keyring] = ENV['ARCH_KEYRING_MIRROR']
end

if ENV['ARCH_PACMAN_MIRROR'].is_a?(String) and !ENV['ARCH_PACMAN_MIRROR'].empty?
  node[:archbootstrap][:mirror][:pacman] = ENV['ARCH_PACMAN_MIRROR']
end

if ENV['TARGET_DIRECTORY'].is_a?(String) and !ENV['TARGET_DIRECTORY'].empty?
  node[:archbootstrap][:directory][:target][:path] = ENV['TARGET_DIRECTORY']
end

#
# Private Variables
#

mirror    = node[:archbootstrap][:mirror]
directory = node[:archbootstrap][:directory]
filename  = node[:archbootstrap][:filename]

download_squashfs_url  = File.join(mirror[:pacman], '/iso/latest/arch/x86_64/', filename[:squashfs][:name])
download_checksum_url  = File.join(mirror[:pacman], '/iso/latest/arch/x86_64/', filename[:checksum][:name])
download_squashfs_path = File.join(directory[:download][:path], filename[:squashfs][:name])
download_checksum_path = File.join(directory[:download][:path], filename[:checksum][:name])

checksum_archive = "grep #{filename[:squashfs][:name]} #{filename[:checksum][:name]}"
checksum_command = 'sha512sum -c --ignore-missing --status'

resolv_conf_path = File.join(directory[:extract][:path], '/etc/resolv.conf')
mirror_list_path = File.join(directory[:extract][:path], '/etc/pacman.d/mirrorlist')
keyring_dir_path = File.join(directory[:extract][:path], '/etc/pacman.d/gnupg')

#
# Private Variables - Mount Target Directory
#

mounts = [
  {
    :target  => File.join(directory[:extract][:path], 'dev'),
    :device  => 'devtmpfs',
    :type    => 'devtmpfs',
  },
  {
    :target  => File.join(directory[:extract][:path], 'dev', 'pts'),
    :device  => 'devpts',
    :type    => 'devpts',
    :options => ['gid=5', 'mode=620'],
  },
  {
    :target  => File.join(directory[:extract][:path], 'proc'),
    :device  => 'proc',
    :type    => 'proc',
  },
  {
    :target  => File.join(directory[:extract][:path], 'run'),
    :device  => 'tmpfs',
    :type    => 'tmpfs',
    :options => ['mode=755'],
  },
  {
    :target  => File.join(directory[:extract][:path], 'sys'),
    :device  => 'sysfs',
    :type    => 'sysfs',
  },
  {
    :target  => File.join(directory[:extract][:path], 'tmp'),
    :device  => 'tmpfs',
    :type    => 'tmpfs',
  },
  {
    :target  => File.join(directory[:extract][:path], 'mnt'),
    :device  => directory[:target][:path],
    :options => ['bind'],
  },
]

#
# Required Packages
#

package 'squashfs-tools'

#
# Target Directory
#

directory directory[:target][:path] do
  owner directory[:target][:owner]
  group directory[:target][:group]
  mode  directory[:target][:mode]
end

#
# Download Directory
#

directory directory[:download][:path] do
  owner  directory[:download][:owner]
  group  directory[:download][:group]
  mode   directory[:download][:mode]
  not_if [
    "test -x #{File.join(directory[:target][:path], '/usr/bin/pacman')}",
    "test -d #{directory[:extract][:path]}",
  ].join(' || ')
end

#
# Download Bootstrap Checksum File
#

http_request download_checksum_path do
  cwd    directory[:download][:path]
  url    download_checksum_url
  owner  filename[:checksum][:owner]
  group  filename[:checksum][:group]
  mode   filename[:checksum][:mode]
  not_if [
    "test -x #{File.join(directory[:target][:path], '/usr/bin/pacman')}",
    "test -d #{directory[:extract][:path]}",
    "test -f #{filename[:checksum][:name]}",
  ].join(' || ')
end

#
# Download Bootstrap SquashFS Image
#

http_request download_squashfs_path do
  cwd    directory[:download][:path]
  url    download_squashfs_url
  owner  filename[:squashfs][:owner]
  group  filename[:squashfs][:group]
  mode   filename[:squashfs][:mode]
  not_if [
    "test -x #{File.join(directory[:target][:path], '/usr/bin/pacman')}",
    "test -d #{directory[:extract][:path]}",
    "#{checksum_archive} | #{checksum_command}",
  ].join(' || ')
end

#
# Extract Bootstrap SquashFS Image
#

execute "unsquashfs -d #{directory[:extract][:path]} #{filename[:squashfs][:name]}" do
  cwd    directory[:download][:path]
  not_if [
    "test -x #{File.join(directory[:target][:path], '/usr/bin/pacman')}",
    "test -d #{directory[:extract][:path]}",
  ].join(' || ')
end

#
# Remove Symbolic Link Resolv.conf
#

file resolv_conf_path do
  action :delete
  not_if [
    "test -x #{File.join(directory[:target][:path], '/usr/bin/pacman')}",
    "test \"'#{resolv_conf_path}'\" = \"$(stat -c '%N' #{resolv_conf_path})\"",
  ].join(' || ')
end

#
# Create Plain Text Resolv.conf
#

file resolv_conf_path do
  owner   'root'
  group   'root'
  mode    '0644'
  content File.read('/etc/resolv.conf')
  not_if  "test -x #{File.join(directory[:target][:path], '/usr/bin/pacman')}"
end

#
# Create Pacman Mirror List
#

file mirror_list_path do
  owner   'root'
  group   'root'
  mode    '0644'
  content "Server = #{File.join(mirror[:pacman], '/$repo/os/$arch')}"
  not_if  "test -x #{File.join(directory[:target][:path], '/usr/bin/pacman')}"
end

#
# Mount Pacstrap System
#

mounts.each do |v|
  mount v[:target] do
    device  v[:device]
    type    v[:type]
    options v[:options]
    not_if  "test -x #{File.join(directory[:target][:path], '/usr/bin/pacman')}"
  end
end

#
# Workaround: If Host Machine Distribution is Debian or Ubuntu
#

directory File.join(directory[:extract][:path], '/dev/shm') do
  mode   '1777'
  not_if "test -x #{File.join(directory[:target][:path], '/usr/bin/pacman')}"
end

#
# Initialize Pacman Keyring
#

execute "chroot #{directory[:extract][:path]} pacman-key --init" do
  not_if [
    "test -x #{File.join(directory[:target][:path], '/usr/bin/pacman')}",
    "test -d #{keyring_dir_path}",
  ].join(' || ')
end

#
# Verify Pacman Keyring
#

execute "chroot #{directory[:extract][:path]} pacman-key --populate archlinux --keyserver #{mirror[:keyring]}" do
  not_if [
    "test -x #{File.join(directory[:target][:path], '/usr/bin/pacman')}",
    "test \"$(chroot #{directory[:extract][:path]} sh -c 'pacman-key -f | grep ^uid | wc -l')\" != 1",
  ].join(' || ')
end

#
# Bootstrap Base System
#

execute "chroot #{directory[:extract][:path]} pacstrap /mnt base curl diffutils" do
  not_if "test -x #{File.join(directory[:target][:path], '/usr/bin/pacman')}"
end

#
# Workaround: Arch Linux: Kill GPG Agent
#

execute [
  "for pid in $(lsof +D #{directory[:extract][:path]} 2>/dev/null | tail -n+2 | tr -s ' ' | cut -d ' ' -f 2 | sort -nu); do",
  "kill -KILL $pid;",
  "done",
].join(' ')

#
# Unmount Pacstrap System
#

mounts.reverse.each do |v|
  mount v[:target] do
    action :absent
  end
end
