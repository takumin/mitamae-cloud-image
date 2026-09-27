# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match(/desktop/)
  return
end

#
# Select Distribution
#

include_recipe node.platform

# Ubuntu's network-manager ships /usr/lib/NetworkManager/conf.d/
# 10-globally-managed-devices.conf, which restricts NetworkManager to wifi
# and wwan devices and leaves wired interfaces unmanaged; mask it with an
# empty file of the same name so that every interface is managed
file '/etc/NetworkManager/conf.d/10-globally-managed-devices.conf' do
  owner   'root'
  group   'root'
  mode    '0644'
  content ''
  only_if 'test -d /etc/NetworkManager/conf.d'
end

# Remove Example Desktop Entry
file '/etc/skel/examples.desktop' do
  action :delete
end

# Open folders in the list view by default
file '/usr/share/glib-2.0/schemas/99_nautilus.gschema.override' do
  owner 'root'
  group 'root'
  mode  '0644'
  content [
    '[org.gnome.nautilus.preferences]',
    "default-folder-viewer='list-view'",
  ].join("\n").concat("\n")
  only_if 'test -f /usr/share/glib-2.0/schemas/org.gnome.nautilus.gschema.xml'
  notifies :run, 'execute[glib-compile-schemas /usr/share/glib-2.0/schemas]'
end

execute 'glib-compile-schemas /usr/share/glib-2.0/schemas' do
  action :nothing
end
