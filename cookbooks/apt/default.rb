# frozen_string_literal: true

#
# Public Variables
#

node[:apt]                ||= Hashie::Mash.new
node[:apt][:distribution] ||= node[:target][:distribution]
node[:apt][:architecture] ||= node[:target][:architecture]
node[:apt][:suite]        ||= node[:target][:suite]
node[:apt][:components]   ||= node[:target][:components]
node[:apt][:mirror_url]   ||= String.new
node[:apt][:target_dir]   ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]

#
# Default Variables
#

case node[:apt][:distribution]
when 'ubuntu'
  case node[:apt][:architecture]
  when 'i386', 'amd64'
    if ENV['APT_REPO_URL_UBUNTU'].is_a?(String) and !ENV['APT_REPO_URL_UBUNTU'].empty?
      node[:apt][:mirror_url] = ENV['APT_REPO_URL_UBUNTU']
    else
      if node[:apt][:mirror_url].empty?
        node[:apt][:mirror_url] = 'http://archive.ubuntu.com/ubuntu'
      end
    end
  when 'armhf', 'arm64'
    if ENV['APT_REPO_URL_UBUNTU_PORTS'].is_a?(String) and !ENV['APT_REPO_URL_UBUNTU_PORTS'].empty?
      node[:apt][:mirror_url] = ENV['APT_REPO_URL_UBUNTU_PORTS']
    else
      if node[:apt][:mirror_url].empty?
        node[:apt][:mirror_url] = 'http://ports.ubuntu.com/ubuntu'
      end
    end
  end
when 'debian'
  if ENV['APT_REPO_URL_DEBIAN'].is_a?(String) and !ENV['APT_REPO_URL_DEBIAN'].empty?
    node[:apt][:mirror_url] = ENV['APT_REPO_URL_DEBIAN']
  else
    if node[:apt][:mirror_url].empty?
      node[:apt][:mirror_url] = 'http://deb.debian.org/debian'
    end
  end
end

#
# Validate Variables
#

node.validate! do
  {
    apt: {
      distribution: match(/^(?:debian|ubuntu)$/),
      suite:        string,
      components:   array_of(string),
      mirror_url:   match(/^(?:https?|file):\/\//),
      target_dir:   string,
    },
  }
end

case node[:apt][:distribution].to_sym
when :ubuntu
  node.validate! do
    {
      apt: {
        suite:        match(/^(?:xenial|bionic)$/),
        components:   array_of(match(/^(?:main|restricted|universe|multiverse)$/)),
      },
    }
  end
when :debian
  node.validate! do
    {
      apt: {
        suite:        match(/^(?:jessie|stretch|buster)$/),
        components:   array_of(match(/^(?:main|contrib|non-free)$/)),
      },
    }
  end
end

#
# Private Variables
#

case node[:apt][:distribution].to_sym
when :ubuntu
  default_uri = 'http://archive.ubuntu.com/ubuntu'
when :debian
  default_uri = 'http://deb.debian.org/debian'
end

#
# Apt Repository
#

apt_repository "#{node[:apt][:target_dir]}/etc/apt/sources.list" do
  header [
    '#',
    '# Official Repository',
    '#',
  ]
  entry [
    {
      :default_uri => default_uri,
      :mirror_uri  => "#{node[:apt][:mirror_url]}",
      :suite       => "#{node[:apt][:suite]}",
      :components  => node[:apt][:components],
    },
    {
      :default_uri => default_uri,
      :mirror_uri  => "#{node[:apt][:mirror_url]}",
      :suite       => "#{node[:apt][:suite]}-updates",
      :components  => node[:apt][:components],
    },
    {
      :default_uri => default_uri,
      :mirror_uri  => "#{node[:apt][:mirror_url]}",
      :suite       => "#{node[:apt][:suite]}-backports",
      :components  => node[:apt][:components],
    },
    {
      :default_uri => default_uri,
      :mirror_uri  => "#{node[:apt][:mirror_url]}",
      :suite       => "#{node[:apt][:suite]}-security",
      :components  => node[:apt][:components],
    },
  ]
  notifies :run, 'execute[apt-get update]'
end

#
# Required Packages
#

package 'systemd-container'

#
# Handler
#

execute 'apt-get update' do
  action :nothing
  command "systemd-nspawn -D #{node[:apt][:target_dir]} apt-get update"
end
