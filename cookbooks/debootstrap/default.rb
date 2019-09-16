# frozen_string_literal: true

#
# Public Variables
#

node[:debootstrap]                ||= Hashie::Mash.new
node[:debootstrap][:command]      ||= String.new
node[:debootstrap][:distribution] ||= String.new
node[:debootstrap][:architecture] ||= String.new
node[:debootstrap][:suite]        ||= String.new
node[:debootstrap][:flavour]      ||= String.new
node[:debootstrap][:components]   ||= Array.new
node[:debootstrap][:includes]     ||= Array.new
node[:debootstrap][:excludes]     ||= Array.new
node[:debootstrap][:mirror_url]   ||= String.new
node[:debootstrap][:target_dir]   ||= ENV['TARGET_DIRECTORY'] || String.new

#
# Override Variables
#

if node.key?(:target)
  node[:target].each do |k, v|
    case k.to_sym
    when :directory
      if node[:target][k].is_a?(String) and !node[:target][k].empty?
        node[:debootstrap][:target_dir] = v
      end
    when :distribution, :architecture, :suite, :flavour, :mirror_url
      if node[:target][k].is_a?(String) and !node[:target][k].empty?
        node[:debootstrap][k] = v
      end
    when :components, :includes, :excludes
      if node[:target][k].is_a?(Array) and !node[:target][k].empty?
        node[:debootstrap][k] = v
      end
    end
  end
end

#
# Environment Variables
#

case node[:debootstrap][:distribution]
when 'ubuntu'
  case node[:debootstrap][:architecture]
  when 'i386', 'amd64'
    node[:debootstrap][:mirror_url] = ENV['APT_REPO_URL_UBUNTU']
  when 'armhf', 'arm64'
    node[:debootstrap][:mirror_url] = ENV['APT_REPO_URL_UBUNTU_PORTS']
  end
when 'debian'
  node[:debootstrap][:mirror_url] = ENV['APT_REPO_URL_DEBIAN']
end

#
# Default Variables
#

if node[:debootstrap][:command].empty? then
  node[:debootstrap][:command] = 'debootstrap'

  %w{cdebootstrap}.each do |cmd|
    if run_command("#{cmd} --version", error: false).success?
      node[:debootstrap][:command] = cmd
      break
    end
  end
end

if node[:debootstrap][:mirror_url].empty? then
  case node[:debootstrap][:distribution]
  when 'ubuntu'
    case node[:debootstrap][:architecture]
    when 'i386', 'amd64'
      node[:debootstrap][:mirror_url] = 'http://jp.archive.ubuntu.com/ubuntu'
    when 'armhf', 'arm64'
      node[:debootstrap][:mirror_url] = 'http://jp.archive.ubuntu.com/ubuntu-ports'
    end
  when 'debian'
    node[:debootstrap][:mirror_url] = 'http://ftp.jp.debian.org/debian'
  end
end

if node[:debootstrap][:target_dir].empty? then
  node[:debootstrap][:target_dir] = "/tmp/#{[
    node[:debootstrap][:distribution],
    node[:debootstrap][:architecture],
    node[:debootstrap][:suite],
    node[:debootstrap][:flavour],
  ].join('-')}"
end

#
# Validate Variables
#

node.validate! do
  {
    debootstrap: {
      command:      match(/^(?:c?debootstrap)$/),
      distribution: match(/^(?:debian|ubuntu)$/),
      architecture: match(/^(?:i386|amd64|armhf|arm64)$/),
      suite:        string,
      flavour:      match(/^(?:default|minimal|build)$/),
      components:   array_of(string),
      includes:     array_of(string),
      excludes:     array_of(string),
      mirror_url:   match(/^(?:https?|file):\/\//),
      target_dir:   string,
    },
  }
end

case node[:debootstrap][:distribution]
when 'ubuntu'
  node.validate! do
    {
      debootstrap: {
        suite:        match(/^(?:xenial|bionic)$/),
        components:   array_of(match(/^(?:main|restricted|universe|multiverse)$/)),
      },
    }
  end
when 'debian'
  node.validate! do
    {
      debootstrap: {
        suite:        match(/^(?:jessie|stretch|buster)$/),
        components:   array_of(match(/^(?:main|contrib|non-free)$/)),
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
mirror     = node[:debootstrap][:mirror_url]
target     = node[:debootstrap][:target_dir]

#
# Required Packages
#

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
# Show Variables
#

MItamae.logger.info "Debootstrap Infomation"
MItamae.logger.info "  Command:      #{cmd}"
MItamae.logger.info "  Distribution: #{dist}"
MItamae.logger.info "  Architecture: #{arch}"
MItamae.logger.info "  Suite:        #{suite}"
MItamae.logger.info "  Flavour:      #{flavour}"
MItamae.logger.info "  Components:   #{components}"
MItamae.logger.info "  Includes:     #{includes}"
MItamae.logger.info "  Excludes:     #{excludes}"
MItamae.logger.info "  Mirror Url:   #{mirror}"
MItamae.logger.info "  Target Dir:   #{target}"

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
