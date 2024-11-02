#
# Apt Pinned
#

file '/etc/apt/preferences.d/powerdns' do
  owner 'root'
  group 'root'
  mode  '0644'
  content <<~__EOF__
    Package: *
    Pin: release o=PowerDNS
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

remote_file '/etc/apt/keyrings/powerdns.asc' do
  owner  'root'
  group  'root'
  mode   '0644'
  source 'keyring.asc'
end

#
# Apt Repository
#

apt_repository 'PowerDNS Repository' do
  path '/etc/apt/sources.list.d/powerdns.list'
  entry [
    {
      :default_uri => "http://repo.powerdns.com/#{node.platform}",
      :mirror_uri  => ENV['APT_REPO_URL_POWERDNS_' + node.platform.upcase],
      :options     => 'signed-by=/etc/apt/keyrings/powerdns.asc',
      :suite       => '###platform_codename###-auth-49',
      :components  => ['main'],
    },
    {
      :default_uri => "http://repo.powerdns.com/#{node.platform}",
      :mirror_uri  => ENV['APT_REPO_URL_POWERDNS_' + node.platform.upcase],
      :options     => 'signed-by=/etc/apt/keyrings/powerdns.asc',
      :suite       => '###platform_codename###-rec-51',
      :components  => ['main'],
    },
    {
      :default_uri => "http://repo.powerdns.com/#{node.platform}",
      :mirror_uri  => ENV['APT_REPO_URL_POWERDNS_' + node.platform.upcase],
      :options     => 'signed-by=/etc/apt/keyrings/powerdns.asc',
      :suite       => '###platform_codename###-dnsdist-19',
      :components  => ['main'],
    },
  ]
  notifies :run, 'execute[apt-get update]', :immediately
end

#
# Event Handler
#

execute 'apt-get update' do
  action :nothing
end

#
# Required Packages
#

# package 'dnsdist'
# package 'pdns-server'
package 'pdns-recursor'
