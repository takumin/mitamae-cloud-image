# frozen_string_literal: true

#
# Public Variables
#

node[:debootstrap]                ||= Hashie::Mash.new
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
# Default Variables
#

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
# Private Variables
#

params = Hashie::Mash.new({
  :debian => {
    :architectures => [
      'i386',
      'amd64',
      'armhf',
      'arm64',
    ],
    :suites => [
      'jessie',
      'stretch',
    ],
    :variants => [
      'default',
      'minbase',
      'buildd',
      'fakechroot',
    ],
    :components => [
      'main',
      'contrib',
      'non-free',
    ],
  },
  :ubuntu => {
    :architectures => [
      'i386',
      'amd64',
      'armhf',
      'arm64',
    ],
    :suites => [
      'xenial',
      'bionic',
    ],
    :variants => [
      'default',
      'minbase',
      'buildd',
      'fakechroot',
    ],
    :components => [
      'main',
      'restricted',
      'universe',
      'multiverse',
    ],
  },
})

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
# Check Variables
#

unless params.key?(dist) then
  raise ArgumentError, "node[:debootstrap][:distribution] require #{params.keys.join(' or ')}"
end

unless params[dist][:architectures].include?(arch) then
  raise ArgumentError, "node[:debootstrap][:architectures] require #{params[dist][:architectures].join(' or ')}"
end

unless params[dist][:suites].include?(suite) then
  raise ArgumentError, "node[:debootstrap][:suite] require #{params[dist][:suites].join(' or ')}"
end

unless params[dist][:variants].include?(variant) then
  raise ArgumentError, "node[:debootstrap][:variant] require #{params[dist][:variants].join(' or ')}"
end

components.each do |component|
  unless params[dist][:components].include?(component) then
    raise ArgumentError, "node[:debootstrap][:components] require #{params[dist][:components].join(' or ')}"
  end
end

unless mirror.match(/^https?:\/\/|ssh:\/\/|file:\/\//) then
  raise ArgumentError, "node[:debootstrap][:mirror_url] require http:// or https:// or ssh:// or file://"
end

if target.empty? then
  raise ArgumentError, "node[:debootstrap][:target_dir] require target directory"
end

#
# Show Variables
#

MItamae.logger.info "Debootstrap Infomation"
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

cmd = ['debootstrap']
cmd << "--arch=#{arch}"
cmd << "--variant=#{variant}" if variant != 'default'
cmd << "--components=#{components.join(',')}"
cmd << "--include=#{includes.join(',')}" unless includes.empty?
cmd << "--exclude=#{excludes.join(',')}" unless excludes.empty?
cmd << suite
cmd << target
cmd << mirror

#
# Run Debootstrap
#

execute cmd.join(' ') do
  user 'root'
  not_if "test -x #{target}/usr/bin/apt-get"
end
