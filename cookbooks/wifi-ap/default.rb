# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].eql?('kodi-car')
  return
end

#
# Public Variables
#

node[:wifi_ap] ||= Hashie::Mash.new

#
# Public Variables - Interface
#

node[:wifi_ap][:interface] ||= 'wlan0'
node[:wifi_ap][:address]   ||= '192.168.50.1/24'

#
# Public Variables - Radio
#

node[:wifi_ap][:country] ||= 'JP'
node[:wifi_ap][:hw_mode] ||= 'g'
node[:wifi_ap][:channel] ||= 6

#
# Public Variables - Credentials
#

# The SSID and the passphrase are read from this file on the boot medium, so that they stay out of the image.
node[:wifi_ap][:credentials]         ||= Hashie::Mash.new
node[:wifi_ap][:credentials][:label] ||= 'BOOT'
node[:wifi_ap][:credentials][:path]  ||= 'wifi-ap.conf'

#
# Validate Variables
#

node.validate! do
  {
    wifi_ap: {
      interface: match(/^[a-z0-9]+$/),
      address: match(%r{^[0-9.]+/[0-9]+$}),
      country: match(/^[A-Z]{2}$/),
      hw_mode: match(/^[abg]$/),
      channel: integer,
      credentials: {
        label: match(/^[A-Za-z0-9_-]+$/),
        path: match(%r{^[A-Za-z0-9_./-]+$}),
      },
    },
  }
end

#
# Private Variables
#

hostapd_conf = "/etc/hostapd/#{node[:wifi_ap][:interface]}.conf"
runtime_conf = '/run/wifi-ap/hostapd.conf'

#
# Install Package
#

package 'hostapd'
package 'wireless-regdb'

#
# Regulatory Domain
#

file '/etc/modprobe.d/wifi-ap.conf' do
  owner   'root'
  group   'root'
  mode    '0644'
  content "options cfg80211 ieee80211_regdom=#{node[:wifi_ap][:country]}\n"
end

#
# Hostapd
#

directory '/etc/wifi-ap' do
  owner 'root'
  group 'root'
  mode  '0755'
end

template '/etc/wifi-ap/hostapd.conf' do
  owner  'root'
  group  'root'
  mode   '0644'
  source 'templates/hostapd.conf.erb'
end

template '/usr/local/sbin/wifi-ap-config' do
  owner     'root'
  group     'root'
  mode      '0755'
  source    'templates/wifi-ap-config.erb'
  variables runtime_conf: runtime_conf
end

# hostapd@.service skips the start while its configuration is missing or empty, which is the case without
# the credentials file.
link hostapd_conf do
  to    runtime_conf
  force true
end

template '/etc/systemd/system/wifi-ap-config.service' do
  owner  'root'
  group  'root'
  mode   '0644'
  source 'templates/wifi-ap-config.service.erb'
end

directory "/etc/systemd/system/hostapd@#{node[:wifi_ap][:interface]}.service.d" do
  owner 'root'
  group 'root'
  mode  '0755'
end

file "/etc/systemd/system/hostapd@#{node[:wifi_ap][:interface]}.service.d/wifi-ap.conf" do
  owner   'root'
  group   'root'
  mode    '0644'
  content <<~__EOF__
    [Unit]
    Wants=wifi-ap-config.service
    After=wifi-ap-config.service
  __EOF__
end

service "hostapd@#{node[:wifi_ap][:interface]}.service" do
  action :enable
end

#
# Network
#

# Sorts before 99-wireless.network, which the initramfs writes for every wireless interface.
template '/etc/systemd/network/10-wifi-ap.network' do
  owner  'root'
  group  'root'
  mode   '0644'
  source 'templates/wifi-ap.network.erb'
end
