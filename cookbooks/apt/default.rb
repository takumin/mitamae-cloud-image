#
# Public Variables
#

node[:apt]                ||= Hashie::Mash.new
node[:apt][:distribution] ||= String.new
node[:apt][:architecture] ||= String.new
node[:apt][:suite]        ||= String.new
node[:apt][:components]   ||= Array.new
node[:apt][:mirror_url]   ||= String.new
node[:apt][:target_dir]   ||= ENV['TARGET_DIRECTORY'] || String.new

#
# Override Variables
#

if node.key?(:target)
  node[:target].each do |k, v|
    case k.to_sym
    when :directory
      if node[:target][k].is_a?(String) and !node[:target][k].empty?
        node[:apt][:target_dir] = v
      end
    when :distribution, :architecture, :suite, :mirror_url
      if node[:target][k].is_a?(String) and !node[:target][k].empty?
        node[:apt][k] = v
      end
    when :components
      if node[:target][k].is_a?(Array) and !node[:target][k].empty?
        node[:apt][k] = v
      end
    end
  end
end

#
# Environment Variables
#

case node[:apt][:distribution]
when 'ubuntu'
  if ENV['APT_REPO_URL_UBUNTU'].is_a?(String) and ENV['APT_REPO_URL_UBUNTU'].match(/^(?:https?|file):\/\//)
    node[:apt][:mirror_url] = ENV['APT_REPO_URL_UBUNTU']
  end
when 'debian'
  if ENV['APT_REPO_URL_DEBIAN'].is_a?(String) and ENV['APT_REPO_URL_DEBIAN'].match(/^(?:https?|file):\/\//)
    node[:apt][:mirror_url] = ENV['APT_REPO_URL_DEBIAN']
  end
end

#
# Default Variables
#

if node[:apt][:mirror_url].empty? then
  case node[:apt][:distribution]
  when 'ubuntu'
    case node[:apt][:architecture]
    when 'i386', 'amd64'
      node[:apt][:mirror_url] = 'http://jp.archive.ubuntu.com/ubuntu'
    when 'armhf', 'arm64'
      node[:apt][:mirror_url] = 'http://jp.archive.ubuntu.com/ubuntu-ports'
    end
  when 'debian'
    node[:apt][:mirror_url] = 'http://ftp.jp.debian.org/debian'
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
