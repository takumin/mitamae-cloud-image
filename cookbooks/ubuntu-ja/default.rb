# frozen_string_literal: true

#
# Apt Keyrings
#

apt_keyring 'Ubuntu-ja Archive Automatic Signing Key <archive@ubuntulinux.jp>' do
  finger '3B593C7BE6DB6A89FB7CBFFD058A05E90C4ECFEC'
  uri 'https://www.ubuntulinux.jp/ubuntu-ja-archive-keyring.gpg'
end

apt_keyring 'Launchpad PPA for Ubuntu Japanese Team' do
  finger '59676CBCF5DFD8C1CEFE375B68B5F60DCDC1D865'
  uri 'https://www.ubuntulinux.jp/ubuntu-jp-ppa-keyring.gpg'
end

#
# Apt Repository
#

apt_repository 'Ubuntu Japanese Team Repository' do
  path '/etc/apt/sources.list.d/ubuntu-ja.list'
  entry [
    {
      :default_uri => 'http://archive.ubuntulinux.jp/ubuntu',
      :mirror_uri  => "#{ENV['APT_REPO_URL_UBUNTU_JA']}",
      :suite       => '###platform_codename###',
      :components  => [
        'main',
      ],
    },
    {
      :default_uri => 'http://archive.ubuntulinux.jp/ubuntu-ja-non-free',
      :mirror_uri  => "#{ENV['APT_REPO_URL_UBUNTU_JA_NON_FREE']}",
      :suite       => '###platform_codename###',
      :components  => [
        'multiverse',
      ],
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
# Check Platform
#

unless node[:target][:role].match(/desktop/)
  return
end

#
# Install Packages
#

package 'ubuntu-defaults-ja'

#
# Input Method
#

package 'fcitx'
package 'fcitx-mozc'

#
# Default Input Method for Fcitx
#

file '/usr/share/glib-2.0/schemas/99_input-method.gschema.override' do
  owner 'root'
  group 'root'
  mode  '0644'
  content [
    '[org.gnome.settings-daemon.plugins.keyboard]',
    'active=false',
  ].join("\n")
  notifies :run, 'execute[glib-compile-schemas /usr/share/glib-2.0/schemas]'
end

#
# Compile Glib Schemas
#

execute 'glib-compile-schemas /usr/share/glib-2.0/schemas' do
  action :nothing
end

#
# Home Directory Locale
#

file '/etc/xdg/user-dirs.conf' do
  action :edit
  block do |content|
    content.gsub!(/^filename_encoding=UTF-8$/, 'filename_encoding=en_US.UTF-8')
  end
end
