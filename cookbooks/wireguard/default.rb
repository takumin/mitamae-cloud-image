# frozen_string_literal: true

#
# Apt Repository
#

apt_keyring 'Launchpad PPA for wireguard-ppa' do
  finger 'E1B39B6EF6DDB96564797591AE33835F504A1A25'
end

apt_repository 'WireGuard Repository' do
  path '/etc/apt/sources.list.d/wireguard.list'
  entry [
    {
      :default_uri => 'http://ppa.launchpad.net/wireguard/wireguard/ubuntu',
      :mirror_uri  => "#{ENV['APT_REPO_URL_PPA_WIREGUARD']}",
      :suite       => '###platform_codename###',
      :components  => [
        'main',
      ],
    },
  ]
  notifies :run, 'execute[apt-get update]', :immediately
end

execute 'apt-get update' do
  action :nothing
end

#
# Required Packages
#

case "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}"
when /^ubuntu-(?:[0-9]+)\.(?:[0-9]+)-generic$/
  package 'linux-headers-generic'
when /^ubuntu-16\.04-generic-hwe$/
  package 'linux-headers-generic-hwe-16.04'
when /^ubuntu-18\.04-generic-hwe$/
  package 'linux-headers-generic-hwe-18.04'
else
  MItamae.logger.error "Unknown platform: #{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}"
  exit 1
end

#
# Install Package
#

package 'wireguard'
