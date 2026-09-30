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

# A network boot leaves the interfaces configured by the initramfs ipconfig, and NetworkManager assumes them
# as external in-memory connections instead of activating the cloud-init ones, so each interface shows up
# twice; activate the persistent connections on startup instead (the fetched rootfs lives in RAM, so
# reconfiguring the boot interface is safe)
file '/etc/NetworkManager/conf.d/90-no-keep-configuration.conf' do
  owner   'root'
  group   'root'
  mode    '0644'
  content [
    '[device-90-no-keep-configuration]',
    'match-device=type:ethernet',
    'keep-configuration=no',
  ].join("\n").concat("\n")
  only_if 'test -d /etc/NetworkManager/conf.d'
end

# Keep suspend in RAM only; hibernation writes the whole memory to disk, which is slow on a HDD and wears
# out an SSD, so forbid every sleep mode that involves it
directory '/etc/systemd/sleep.conf.d' do
  owner 'root'
  group 'root'
  mode  '0755'
end

file '/etc/systemd/sleep.conf.d/90-suspend-to-ram-only.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  content [
    '[Sleep]',
    'AllowHibernation=no',
    'AllowSuspendThenHibernate=no',
    'AllowHybridSleep=no',
  ].join("\n").concat("\n")
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

# Never suspend automatically on inactivity while on AC power, but keep the default on battery so that an
# idle laptop does not drain it; gnome-settings-daemon reads these defaults both in the user session and on
# the GDM login screen, so a single override covers both
file '/usr/share/glib-2.0/schemas/99_gnome-settings-daemon-power.gschema.override' do
  owner 'root'
  group 'root'
  mode  '0644'
  content [
    '[org.gnome.settings-daemon.plugins.power]',
    "sleep-inactive-ac-type='nothing'",
  ].join("\n").concat("\n")
  only_if 'test -f /usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.power.gschema.xml'
  notifies :run, 'execute[glib-compile-schemas /usr/share/glib-2.0/schemas]'
end

# power-profiles-daemon always starts in the balanced profile unless its state file records a profile that
# the user selected on the same drivers, so the file cannot be preseeded in a hardware-independent way;
# select the performance profile over D-Bus instead while no profile has been chosen yet, which also saves
# the state file so that a later choice by the user is kept (the legacy bus name is used as it is provided
# by every version; the failure on hardware without the performance profile is ignored)
file '/etc/systemd/system/power-profiles-default-performance.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  content <<~__EOF__
    [Unit]
    Description=Select Performance Power Profile By Default
    Wants=power-profiles-daemon.service
    After=power-profiles-daemon.service
    ConditionPathExists=!/var/lib/power-profiles-daemon/state.ini

    [Service]
    Type=oneshot
    ExecStart=-/usr/bin/busctl set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile s performance

    [Install]
    WantedBy=graphical.target
  __EOF__
  only_if 'test -f /usr/lib/systemd/system/power-profiles-daemon.service'
end

service 'power-profiles-default-performance.service' do
  action :enable
  only_if 'test -f /etc/systemd/system/power-profiles-default-performance.service'
end

execute 'glib-compile-schemas /usr/share/glib-2.0/schemas' do
  action :nothing
end
