# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match(/desktop/)
  return
end

#
# Required Packages
#

case "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}"
when 'ubuntu-18.04-generic-hwe'
  package 'xserver-xorg-hwe-18.04'
end

#
# Check Platform
#

if node[:platform].match(/ubuntu/)
  #
  # Ubuntu Mozilla Team Keyring
  #

  apt_keyring 'Launchpad PPA for Mozilla Team' do
    finger '0AB215679C571D1C8325275B9BDB3D89CE49EC21'
  end

  #
  # Ubuntu Mozilla Team Repository
  #

  apt_repository 'Ubuntu Mozilla Team Repository' do
    path '/etc/apt/sources.list.d/mozillateam.list'
    entry [
      {
        :default_uri => 'https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu',
        :mirror_uri  => "#{ENV['APT_REPO_URL_PPA_MOZILLA_TEAM']}",
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

  file '/etc/apt/preferences.d/mozillateam' do
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
  package 'ubuntu-desktop'
end

# Workaround: Fix System Log Error Message
case "#{node[:platform]}-#{node[:platform_version]}"
when 'ubuntu-18.04'
  package 'gir1.2-clutter-1.0'
  package 'gir1.2-clutter-gst-3.0'
  package 'gir1.2-gtkclutter-1.0'
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
