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

node[:pacman] ||= Hashie::Mash.new

#
# Public Variables - Mirror
#

node[:pacman][:mirror]           ||= Hashie::Mash.new
node[:pacman][:mirror][:keyring] ||= 'hkp://p80.pool.sks-keyservers.net:80'
node[:pacman][:mirror][:pacman]  ||= 'https://mirror.rackspace.com/archlinux/'

#
# Default Variables
#

if ENV['ARCH_KEYRING_MIRROR'].is_a?(String) and !ENV['ARCH_KEYRING_MIRROR'].empty?
  node[:pacman][:mirror][:keyring] = ENV['ARCH_KEYRING_MIRROR']
end

if ENV['ARCH_PACMAN_MIRROR'].is_a?(String) and !ENV['ARCH_PACMAN_MIRROR'].empty?
  node[:pacman][:mirror][:pacman] = ENV['ARCH_PACMAN_MIRROR']
end

#
# Initialize Keyring
#

execute 'pacman-key --init' do
  not_if 'test -d /etc/pacman.d/gnupg'
end

#
# Verify Keyring
#

execute "pacman-key --populate archlinux --keyserver #{node[:pacman][:mirror][:keyring]}" do
  only_if 'test \"$(pacman-key -f | grep ^uid | wc -l)\" = "1"'
end

#
# Mirror List
#

file '/etc/pacman.d/mirrorlist' do
  owner   'root'
  group   'root'
  mode    '0644'
  content "Server = #{File.join(node[:pacman][:mirror][:pacman], '/$repo/os/$arch')}"
end

#
# Update Repository
#

execute 'pacman -Sy --noconfirm'
