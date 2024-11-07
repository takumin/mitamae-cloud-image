# frozen_string_literal: true

#
# Check Roles
#

unless node.target.role.match(/bootstrap/)
  return
end

#
# Apt Pinned
#

file '/etc/apt/preferences.d/isc-kea' do
  owner 'root'
  group 'root'
  mode  '0644'
  content <<~__EOF__
    Package: *
    Pin: release o=cloudsmith/isc/kea-2-6
    Pin-Priority: 600
  __EOF__
end

#
# Apt Keyring
#

directory '/etc/apt/keyrings' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/etc/apt/keyrings/isc-kea.asc' do
  owner  'root'
  group  'root'
  mode   '0644'
  source 'keyring.asc'
end

#
# Apt Repository
#

apt_repository 'ISC Kea Repository' do
  path '/etc/apt/sources.list.d/isc-kea.list'
  entry [
    {
      :default_uri => "https://dl.cloudsmith.io/public/isc/kea-2-6/deb/#{node.platform}",
      :mirror_uri  => ENV['APT_REPO_URL_ISC_KEA_' + node.platform.upcase],
      :options     => 'signed-by=/etc/apt/keyrings/isc-kea.asc',
      :suite       => '###platform_codename###',
      :components  => ['main'],
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

package 'isc-kea'
