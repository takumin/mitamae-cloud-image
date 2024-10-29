# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match(/desktop/)
  return
end

#
# Check Platform
#

if node[:platform].match(/ubuntu/)
  #
  # Ubuntu Mozilla Team Keyring
  #

  directory '/etc/apt/keyrings' do
    owner 'root'
    group 'root'
    mode '0755'
  end

  http_request '/etc/apt/keyrings/ppa-ubuntu-mozilla-team.gpg.asc' do
    url 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xaebdf4819be21867'
    owner 'root'
    group 'root'
    mode '0644'
    not_if 'test -e /etc/apt/keyrings/ppa-ubuntu-mozilla-team.gpg.asc'
  end

  #
  # PPA Ubuntu Mozilla Team Repository
  #

  apt_repository 'PPA Ubuntu Mozilla Team Repository' do
    path '/etc/apt/sources.list.d/ppa-ubuntu-mozilla-team.list'
    entry [
      {
        :default_uri => 'https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu',
        :mirror_uri  => "#{ENV['APT_REPO_URL_PPA_MOZILLA_TEAM']}",
        :options     => 'signed-by=/etc/apt/keyrings/ppa-ubuntu-mozilla-team.gpg.asc',
        :suite       => '###platform_codename###',
        :components  => [
          'main',
        ],
      },
    ]
    notifies :run, 'execute[apt-get update]', :immediately
  end

  #
  # Ubuntu Mozilla Team Preferences
  #

  contents = [
    'Package: *',
    'Pin: release o=LP-PPA-mozillateam',
    'Pin-Priority: 600',
  ].join("\n")

  file '/etc/apt/preferences.d/ppa-ubuntu-mozilla-team' do
    owner   'root'
    group   'root'
    mode    '0644'
    content "#{contents}\n"
  end

  #
  # Event Handler
  #

  execute 'apt-get update' do
    action :nothing
  end
end

#
# Package Install
#

case node[:platform]
when 'debian'
  package 'task-desktop'
when 'ubuntu'
  package 'ubuntu-desktop-minimal'
end

# Workaround: Manage all network interfaces with Network Manager
file '/etc/NetworkManager/conf.d/10-globally-managed-devices.conf' do
  owner   'root'
  group   'root'
  mode    '0644'
  only_if 'test -d /etc/NetworkManager/conf.d'
end

# Workaround: Explicitly enable Network Manager for netplan
file '/etc/netplan/01-network-manager-all.yaml' do
  owner   'root'
  group   'root'
  mode    '0644'
  only_if 'test -d /etc/netplan'
  content [
    '# Workaround: Explicitly enable Network Manager',
    'network:',
    '  version: 2',
    '  renderer: NetworkManager',
  ].join("\n")
end

# Remove Example Desktop Entry
file '/etc/skel/examples.desktop' do
  action :delete
end
