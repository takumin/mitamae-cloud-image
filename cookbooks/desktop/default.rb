# frozen_string_literal: true

#
# Check Platform
#

unless node[:target][:role].match(/desktop/)
  return
end

#
# Package Install
#

case node[:platform]
when 'ubuntu'
  package 'ubuntu-desktop'
end

case "#{node[:platform]}-#{node[:platform_version]}"
when 'ubuntu-18.04'
  # Workaround: Fix System Log Error Message
  package 'gir1.2-clutter-1.0'
  package 'gir1.2-clutter-gst-3.0'
  package 'gir1.2-gtkclutter-1.0'

  # Input Method
  package 'fcitx'
  package 'fcitx-mozc'

  # Default Input Method for Fcitx
  file '/usr/share/glib-2.0/schemas/99_japanese-input-method.gschema.override' do
    owner 'root'
    group 'root'
    mode  '0644'
    content [
      '[org.gnome.settings-daemon.plugins.keyboard]',
      'active=false',
    ].join("\n")
    notifies :run, 'execute[glib-compile-schemas /usr/share/glib-2.0/schemas]'
  end

  # Compile Glib Schemas
  execute 'glib-compile-schemas /usr/share/glib-2.0/schemas' do
    action :nothing
  end

  # Home Directory Locale
  file '/etc/xdg/user-dirs.conf' do
    action :edit
    block do |content|
      content.gsub!(/^filename_encoding=UTF-8$/, 'filename_encoding=en_US.UTF-8')
    end
  end

  # Remove Example Desktop Entry
  file '/etc/skel/examples.desktop' do
    action :delete
  end
end
