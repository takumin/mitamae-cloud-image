# frozen_string_literal: true

#
# Public Variables
#

node[:debootstrap]                ||= Hashie::Mash.new
node[:debootstrap][:command]      ||= String.new
node[:debootstrap][:distribution] ||= String.new
node[:debootstrap][:architecture] ||= String.new
node[:debootstrap][:suite]        ||= String.new
node[:debootstrap][:variant]      ||= String.new
node[:debootstrap][:components]   ||= Array.new
node[:debootstrap][:includes]     ||= Array.new
node[:debootstrap][:excludes]     ||= Array.new
node[:debootstrap][:mirror_url]   ||= String.new
node[:debootstrap][:target_dir]   ||= String.new

#
# Override Variables
#

if node.key?(:target)
  node[:target].each do |k, v|
    case k.to_sym
    when :distribution, :architecture, :suite, :variant, :mirror_url, :target_dir
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
# Default Variables
#

if node[:debootstrap][:command].empty? then
  %w{cdebootstrap debootstrap}.each do |cmd|
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
    node[:debootstrap][:variant],
  ].join('-')}"
end

#
# Environment Variables
#

if ENV['DEBOOTSTRAP_MIRROR_URL'] then
  node[:debootstrap][:mirror_url] = ENV['DEBOOTSTRAP_MIRROR_URL']
end

if ENV['DEBOOTSTRAP_TARGET_DIR'] then
  node[:debootstrap][:target_dir] = ENV['DEBOOTSTRAP_TARGET_DIR']
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
      variant:      match(/^(?:default|minimal|build)$/),
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
variant    = node[:debootstrap][:variant]
components = node[:debootstrap][:components]
includes   = node[:debootstrap][:includes]
excludes   = node[:debootstrap][:excludes]
mirror     = node[:debootstrap][:mirror_url]
target     = node[:debootstrap][:target_dir]

#
# Show Variables
#

MItamae.logger.info "Debootstrap Infomation"
MItamae.logger.info "  Command:      #{cmd}"
MItamae.logger.info "  Distribution: #{dist}"
MItamae.logger.info "  Architecture: #{arch}"
MItamae.logger.info "  Suite:        #{suite}"
MItamae.logger.info "  Variant:      #{variant}"
MItamae.logger.info "  Components:   #{components}"
MItamae.logger.info "  Includes:     #{includes}"
MItamae.logger.info "  Excludes:     #{excludes}"
MItamae.logger.info "  Mirror Url:   #{mirror}"
MItamae.logger.info "  Target Dir:   #{target}"

#
# Target Directory
#

directory target

#
# Command Builder
#

cmds = [cmd]
cmds << "--arch=#{arch}"
case variant
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
cmds << suite
cmds << target
cmds << mirror

#
# Run Debootstrap
#

execute cmds.join(' ') do
  user 'root'
  not_if "test -x #{target}/usr/bin/apt-get"
end
