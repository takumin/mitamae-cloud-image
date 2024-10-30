# frozen_string_literal: true

#
# Check Distribution
#

unless node[:target][:distribution].match(/^ubuntu$/)
  return
end

#
# Check Architecture
#

unless node[:target][:architecture].match(/^(?:amd64|i386)$/)
  return
end

#
# Check Role
#

if node[:target][:role].match(/minimal/)
  return
end

#
# Apt Keyrings
#

if node.platform_version.split('.')[0].to_i < 24
  remote_file '/etc/apt/keyrings/ubuntu-ja-archive-keyring.gpg' do
    source 'keyrings/ubuntu-ja-archive-keyring.gpg'
    owner 'root'
    group 'root'
    mode '0644'
    not_if 'test -e /etc/apt/keyrings/ubuntu-ja-archive-keyring.gpg'
  end

  remote_file '/etc/apt/keyrings/ubuntu-jp-ppa-keyring.gpg' do
    source 'keyrings/ubuntu-jp-ppa-keyring.gpg'
    owner 'root'
    group 'root'
    mode '0644'
    not_if 'test -e /etc/apt/keyrings/ubuntu-jp-ppa-keyring.gpg'
  end
end

#
# Apt Repository
#

if node.platform_version.split('.')[0].to_i < 24
  apt_repository 'Ubuntu Japanese Team Repository' do
    path '/etc/apt/sources.list.d/ubuntu-ja.list'
    entry [
      {
        :default_uri => 'http://archive.ubuntulinux.jp/ubuntu',
        :mirror_uri  => "#{ENV['APT_REPO_URL_UBUNTU_JA']}",
        :options     => 'signed-by=/etc/apt/keyrings/ubuntu-ja-archive-keyring.gpg',
        :suite       => '###platform_codename###',
        :components  => [
          'main',
        ],
      },
      {
        :default_uri => 'http://archive.ubuntulinux.jp/ubuntu-ja-non-free',
        :mirror_uri  => "#{ENV['APT_REPO_URL_UBUNTU_JA_NON_FREE']}",
        :options     => 'signed-by=/etc/apt/keyrings/ubuntu-jp-ppa-keyring.gpg',
        :suite       => '###platform_codename###',
        :components  => [
          'multiverse',
        ],
      },
    ]
    notifies :run, 'execute[apt-get update]', :immediately
  end
end

#
# Event Handler
#

execute 'apt-get update' do
  action :nothing
end

#
# CLI Japanese Packages
#

package 'language-pack-ja'

#
# Check Platform
#

unless node[:target][:role].match(/desktop/)
  return
end

#
# GUI Japanese Packages
#

if node.platform_version.split('.')[0].to_i < 24
  package 'ubuntu-defaults-ja'
else
  package 'language-pack-gnome-ja'
  package 'gnome-user-docs-ja'
  package 'fonts-noto-cjk-extra'
end

#
# Input Method
#

package 'fcitx'
package 'fcitx-mozc'

#
# Default Input Method for Fcitx
#

execute 'im-config -n fcitx' do
  not_if 'grep -qs "^run_im fcitx$" /etc/X11/xinit/xinputrc'
  notifies :run, 'execute[cp /etc/X11/xinit/xinputrc /etc/skel/.xinputrc]'
end

execute 'cp /etc/X11/xinit/xinputrc /etc/skel/.xinputrc' do
  action :nothing
end

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

file '/etc/xdg/autostart/xdg-user-dirs.desktop' do
  action :edit
  block do |content|
    content.gsub!(/^Exec=xdg-user-dirs-update$/, 'Exec=env LC_ALL=C xdg-user-dirs-update')
  end
end

file '/etc/xdg/autostart/user-dirs-update-gtk.desktop' do
  action :edit
  block do |content|
    content.gsub!(/^Exec=xdg-user-dirs-gtk-update$/, 'Exec=env LC_ALL=C xdg-user-dirs-gtk-update')
  end
end
