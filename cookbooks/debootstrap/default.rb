# frozen_string_literal: true

#
# Public Variables
#

node[:debootstrap]                          ||= Hashie::Mash.new
node[:debootstrap][:command]                ||= 'debootstrap'
node[:debootstrap][:distribution]           ||= node[:target][:distribution]
node[:debootstrap][:architecture]           ||= node[:target][:architecture]
node[:debootstrap][:suite]                  ||= node[:target][:suite]
node[:debootstrap][:flavour]                ||= 'minimal'
node[:debootstrap][:components]             ||= node[:target][:components]
node[:debootstrap][:includes]               ||= Array.new
node[:debootstrap][:excludes]               ||= Array.new
node[:debootstrap][:ubuntu_mirror]          ||= 'http://archive.ubuntu.com/ubuntu'
node[:debootstrap][:ubuntu_ports_mirror]    ||= 'http://ports.ubuntu.com/ubuntu-ports'
node[:debootstrap][:debian_mirror]          ||= 'http://deb.debian.org/debian'
node[:debootstrap][:debian_security_mirror] ||= 'http://deb.debian.org/debian-security'
node[:debootstrap][:target_dir]             ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]

#
# Default Variables
#

if ENV['APT_REPO_URL_UBUNTU'].is_a?(String) and !ENV['APT_REPO_URL_UBUNTU'].empty?
  node[:debootstrap][:ubuntu_mirror] = ENV['APT_REPO_URL_UBUNTU']
end

if ENV['APT_REPO_URL_UBUNTU_PORTS'].is_a?(String) and !ENV['APT_REPO_URL_UBUNTU_PORTS'].empty?
  node[:debootstrap][:ubuntu_ports_mirror] = ENV['APT_REPO_URL_UBUNTU_PORTS']
end

if ENV['APT_REPO_URL_DEBIAN'].is_a?(String) and !ENV['APT_REPO_URL_DEBIAN'].empty?
  node[:debootstrap][:debian_mirror] = ENV['APT_REPO_URL_DEBIAN']
end

if ENV['APT_REPO_URL_DEBIAN_SECURITY'].is_a?(String) and !ENV['APT_REPO_URL_DEBIAN_SECURITY'].empty?
  node[:debootstrap][:debian_security_mirror] = ENV['APT_REPO_URL_DEBIAN_SECURITY']
end

#
# Validate Variables
#

node.validate! do
  {
    debootstrap: {
      command:                match(/^(?:c?debootstrap)$/),
      distribution:           match(/^(?:debian|ubuntu)$/),
      architecture:           match(/^(?:i386|amd64|armhf|arm64)$/),
      suite:                  string,
      flavour:                match(/^(?:default|minimal|build)$/),
      components:             array_of(string),
      includes:               array_of(string),
      excludes:               array_of(string),
      ubuntu_mirror:          match(/^(?:https?|file):\/\//),
      ubuntu_ports_mirror:    match(/^(?:https?|file):\/\//),
      debian_mirror:          match(/^(?:https?|file):\/\//),
      debian_security_mirror: match(/^(?:https?|file):\/\//),
      target_dir:             string,
    },
  }
end

case node[:debootstrap][:distribution]
when 'ubuntu'
  node.validate! do
    {
      debootstrap: {
        suite:      match(/^(?:xenial|bionic)$/),
        components: array_of(match(/^(?:main|restricted|universe|multiverse)$/)),
      },
    }
  end
when 'debian'
  node.validate! do
    {
      debootstrap: {
        suite:      match(/^(?:jessie|stretch|buster)$/),
        components: array_of(match(/^(?:main|contrib|non-free)$/)),
      },
    }
  end
end

#
# Private Variables
#

cmd        = node[:debootstrap][:command]
dist       = node[:debootstrap][:distribution]
arch       = node[:debootstrap][:architecture]
suite      = node[:debootstrap][:suite]
flavour    = node[:debootstrap][:flavour]
components = node[:debootstrap][:components]
includes   = node[:debootstrap][:includes]
excludes   = node[:debootstrap][:excludes]
target     = node[:debootstrap][:target_dir]

case dist
when 'debian'
  mirror = node[:debootstrap][:debian_mirror]
when 'ubuntu'
  case arch
  when 'i386', 'amd64'
    mirror = node[:debootstrap][:ubuntu_mirror]
  when 'armhf', 'arm64'
    mirror = node[:debootstrap][:ubuntu_ports_mirror]
  end
end

#
# Required Packages
#

package 'binfmt-support'
package 'qemu-user-static'

case cmd
when 'debootstrap'
  package 'debootstrap'
when 'cdebootstrap'
  package 'cdebootstrap'
end

case dist
when 'debian'
  package 'debian-keyring'
when 'ubuntu'
  package 'ubuntu-keyring'
end

#
# Command Builder
#

cmds = [cmd]
if cmd == 'cdebootstrap'
  case dist
  when 'ubuntu'
    cmds << '--keyring=ubuntu-archive-keyring.gpg'
  when 'debian'
    cmds << '--keyring=debian-archive-keyring.gpg'
  end
end
cmds << "--arch=#{arch}"
case flavour
when 'minimal'
  case cmd
  when 'debootstrap'
    cmds << '--variant=minbase'
  when 'cdebootstrap'
    cmds << '--flavour=minimal'
  end
when 'build'
  case cmd
  when 'debootstrap'
    cmds << '--variant=buildd'
  when 'cdebootstrap'
    cmds << '--flavour=build'
  end
end
if cmd == 'debootstrap'
  cmds << "--components=#{components.join(',')}"
end
cmds << "--include=#{includes.join(',')}" unless includes.empty?
cmds << "--exclude=#{excludes.join(',')}" unless excludes.empty?
if cmd == 'cdebootstrap'
  cmds << '--foreign'
end
cmds << suite
cmds << target
cmds << mirror

#
# Run Debootstrap
#

execute cmds.join(' ') do
  not_if "test -x #{target}/usr/bin/apt-get"
end

#
# Copy Qemu Binary
#

case arch
when 'amd64', 'i386'
  # nothing...
when 'armhf'
  execute "cp /usr/bin/qemu-arm-static #{target}/usr/bin/qemu-arm-static" do
    not_if "test -f #{target}/usr/bin/qemu-arm-static"
  end
when 'arm64'
  execute "cp /usr/bin/qemu-aarch64-static #{target}/usr/bin/qemu-aarch64-static" do
    not_if "test -f #{target}/usr/bin/qemu-aarch64-static"
  end
end
