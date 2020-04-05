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
# Install Package
#

package 'wireguard'
