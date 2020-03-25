# frozen_string_literal: true

#
# Public Variables
#

node[:apt]                          ||= Hashie::Mash.new
node[:apt][:distribution]           ||= node[:target][:distribution]
node[:apt][:architecture]           ||= node[:target][:architecture]
node[:apt][:suite]                  ||= node[:target][:suite]
node[:apt][:components]             ||= node[:target][:components]
node[:apt][:ubuntu_mirror]          ||= 'http://archive.ubuntu.com/ubuntu'
node[:apt][:ubuntu_ports_mirror]    ||= 'http://ports.ubuntu.com/ubuntu'
node[:apt][:debian_mirror]          ||= 'http://deb.debian.org/debian'
node[:apt][:debian_security_mirror] ||= 'http://deb.debian.org/debian-security'

#
# Default Variables
#

if ENV['APT_REPO_URL_UBUNTU'].is_a?(String) and !ENV['APT_REPO_URL_UBUNTU'].empty?
  node[:apt][:ubuntu_mirror] = ENV['APT_REPO_URL_UBUNTU']
end

if ENV['APT_REPO_URL_UBUNTU_PORTS'].is_a?(String) and !ENV['APT_REPO_URL_UBUNTU_PORTS'].empty?
  node[:apt][:ubuntu_ports_mirror] = ENV['APT_REPO_URL_UBUNTU_PORTS']
end

if ENV['APT_REPO_URL_DEBIAN'].is_a?(String) and !ENV['APT_REPO_URL_DEBIAN'].empty?
  node[:apt][:debian_mirror] = ENV['APT_REPO_URL_DEBIAN']
end

if ENV['APT_REPO_URL_DEBIAN_SECURITY'].is_a?(String) and !ENV['APT_REPO_URL_DEBIAN_SECURITY'].empty?
  node[:apt][:debian_security_mirror] = ENV['APT_REPO_URL_DEBIAN_SECURITY']
end

#
# Validate Variables
#

node.validate! do
  {
    apt: {
      distribution:           match(/^(?:debian|ubuntu)$/),
      suite:                  string,
      components:             array_of(string),
      ubuntu_mirror:          match(/^(?:https?|file):\/\//),
      ubuntu_ports_mirror:    match(/^(?:https?|file):\/\//),
      debian_mirror:          match(/^(?:https?|file):\/\//),
      debian_security_mirror: match(/^(?:https?|file):\/\//),
    },
  }
end

case node[:apt][:distribution].to_sym
when :ubuntu
  node.validate! do
    {
      apt: {
        suite:      match(/^(?:xenial|bionic)$/),
        components: array_of(match(/^(?:main|restricted|universe|multiverse)$/)),
      },
    }
  end
when :debian
  node.validate! do
    {
      apt: {
        suite:      match(/^(?:jessie|stretch|buster)$/),
        components: array_of(match(/^(?:main|contrib|non-free)$/)),
      },
    }
  end
end

#
# Apt Entry
#

case node[:apt][:distribution].to_sym
when :debian
  default_uri          = 'http://deb.debian.org/debian'
  default_security_uri = 'http://deb.debian.org/debian-security'
  mirror_uri           = node[:apt][:debian_mirror]
  mirror_security_uri  = node[:apt][:debian_security_mirror]

  entry = [
    {
      :default_uri => default_uri,
      :mirror_uri  => mirror_uri,
      :suite       => "#{node[:apt][:suite]}",
      :components  => node[:apt][:components],
    },
    {
      :default_uri => default_uri,
      :mirror_uri  => mirror_uri,
      :suite       => "#{node[:apt][:suite]}-updates",
      :components  => node[:apt][:components],
    },
    {
      :default_uri => default_uri,
      :mirror_uri  => mirror_uri,
      :suite       => "#{node[:apt][:suite]}-backports",
      :components  => node[:apt][:components],
    },
    {
      :default_uri => default_security_uri,
      :mirror_uri  => mirror_security_uri,
      :suite       => "#{node[:apt][:suite]}/updates",
      :components  => node[:apt][:components],
    },
  ]
when :ubuntu
  case node[:apt][:architecture].to_sym
  when :i386, :amd64
    default_uri = 'http://archive.ubuntu.com/ubuntu'
    mirror_uri  = node[:apt][:ubuntu_mirror]
  when :armhf, :arm64
    default_uri = 'http://ports.ubuntu.com/ubuntu'
    mirror_uri  = node[:apt][:ubuntu_ports_mirror]
  end

  entry = [
    {
      :default_uri => default_uri,
      :mirror_uri  => mirror_uri,
      :suite       => "#{node[:apt][:suite]}",
      :components  => node[:apt][:components],
    },
    {
      :default_uri => default_uri,
      :mirror_uri  => mirror_uri,
      :suite       => "#{node[:apt][:suite]}-updates",
      :components  => node[:apt][:components],
    },
    {
      :default_uri => default_uri,
      :mirror_uri  => mirror_uri,
      :suite       => "#{node[:apt][:suite]}-backports",
      :components  => node[:apt][:components],
    },
    {
      :default_uri => default_uri,
      :mirror_uri  => mirror_uri,
      :suite       => "#{node[:apt][:suite]}-security",
      :components  => node[:apt][:components],
    },
  ]
end

#
# Apt Repository
#

apt_repository '/etc/apt/sources.list' do
  header [
    '#',
    '# Official Repository',
    '#',
  ]
  entry entry
  notifies :run, 'execute[apt-get update]'
end

#
# Handler
#

execute 'apt-get update' do
  action :nothing
end
