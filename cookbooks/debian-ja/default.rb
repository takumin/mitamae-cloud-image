# frozen_string_literal: true

#
# Check Distribution
#

unless node[:target][:distribution].match(/^debian$/)
  return
end

#
# Check Architecture
#

unless node[:target][:architecture].match(/^(?:amd64|i386|armhf|arm64)$/)
  return
end

#
# Check Role
#

if node[:target][:role].match(/minimal/)
  return
end

#
# CLI Japanese Packages
#

package 'task-japanese'

#
# Check Platform
#

unless node[:target][:role].match(/desktop/)
  return
end

#
# GUI Japanese Packages
#

package 'task-japanese-desktop'

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
