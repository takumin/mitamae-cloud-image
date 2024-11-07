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

#
# Restore Configuration
#

file '/etc/systemd/system/isc-kea-restore-config.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  content <<~__EOF__
    [Unit]
    Description=ISC Kea Restore Configuration
    Before=isc-kea-ctrl-agent.service
    Before=isc-kea-dhcp-ddns-server.service
    Before=isc-kea-dhcp4-server.service
    Before=isc-kea-dhcp6-server.service
    Wants=srv.mount
    After=srv.mount
    ConditionDirectoryNotEmpty=/srv/kea
    ConditionPathIsDirectory=/etc/kea
    ConditionPathIsReadWrite=/etc/kea

    [Service]
    Type=oneshot
    ExecStart=/usr/bin/rsync -av --delete /srv/kea/ /etc/kea/

    [Install]
    WantedBy=multi-user.target
  __EOF__
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

execute 'systemctl daemon-reload' do
  action :nothing
end

service 'isc-kea-restore-config.service' do
  action :enable
end
