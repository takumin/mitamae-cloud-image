# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match?(/kodi/)
  return
end

#
# Check Kernel
#

unless node[:target][:kernel].eql?('raspberrypi')
  return
end

#
# Public Variables
#

node[:kodi] ||= Hashie::Mash.new

#
# Public Variables - Owner/Group
#

node[:kodi][:owner]        ||= Hashie::Mash.new
node[:kodi][:owner][:name] ||= 'kodi'
node[:kodi][:owner][:uid]  ||= 560
node[:kodi][:group]        ||= Hashie::Mash.new
node[:kodi][:group][:name] ||= 'kodi'
node[:kodi][:group][:gid]  ||= 560

#
# Public Variables - Supplementary Groups
#

node[:kodi][:supplementary_groups] ||= ['audio', 'video', 'render', 'input']

#
# Public Variables - Directory
#

node[:kodi][:directory]         ||= Hashie::Mash.new
node[:kodi][:directory][:path]  ||= '/var/lib/kodi'
node[:kodi][:directory][:owner] ||= node[:kodi][:owner][:name]
node[:kodi][:directory][:group] ||= node[:kodi][:group][:name]
node[:kodi][:directory][:mode]  ||= '0750'

#
# Public Variables - TTY
#

node[:kodi][:tty] ||= 'tty1'

#
# Public Variables - Interface
#

node[:kodi][:language] ||= 'ja_jp'
node[:kodi][:font]     ||= 'Arial'

#
# Public Variables - CEC
#

node[:kodi][:cec] = false if node[:kodi][:cec].nil?

#
# Public Variables - Car
#

car = node[:target][:role].eql?('kodi-car')

# Media in the car is local, and without a wired link network-online.target only comes after the wait-online
# timeout.
node[:kodi][:network_online] = !car if node[:kodi][:network_online].nil?

# The web server and JSON-RPC answer on every interface, and Avahi announces them for the remote apps.
node[:kodi][:remote] = car if node[:kodi][:remote].nil?

#
# Public Variables - Video Sources
#

# The persistent cookbook mounts the SRVDATA partition of the USB disk on /srv.
node[:kodi][:video_sources] ||= car ? ['/srv/share/movie'] : []

#
# Validate Variables
#

node.validate! do
  {
    kodi: {
      owner: { name: string, uid: integer },
      group: { name: string, gid: integer },
      supplementary_groups: array_of(string),
      directory: { path: string, owner: string, group: string, mode: string },
      tty: match(/^tty[0-9]+$/),
      language: match(/^[a-z]+_[a-z]+$/),
      font: string,
      cec: boolean,
      network_online: boolean,
      remote: boolean,
      video_sources: array_of(match(%r{^/.+[^/]$})),
    },
  }
end

#
# Private Variables
#

language_addon = "resource.language.#{node[:kodi][:language]}"
kodi_home      = "#{node[:kodi][:directory][:path]}/.kodi"
appliance_xml  = '/usr/share/kodi/system/settings/appliance.xml'
cec_settings   = "#{kodi_home}/userdata/peripheral_data/cec_CEC_Adapter.xml"
sources_xml    = "#{kodi_home}/userdata/sources.xml"

#
# Install Package
#

package 'kodi' do
  options '--no-install-recommends'
end

# The skin fonts are symlinks into these packages, which kodi-data only recommends.
%W{
  fonts-noto-core
  fonts-noto-mono
  fonts-roboto-unhinted
}.each do |pkg|
  package pkg do
    options '--no-install-recommends'
  end
end

# kodi-data links Roboto-Thin one directory above where fonts-roboto-unhinted installs it.
link '/usr/share/kodi/addons/skin.estuary/fonts/Roboto-Thin.ttf' do
  to    '/usr/share/fonts/truetype/roboto/unhinted/RobotoTTF/Roboto-Thin.ttf'
  force true
end

# Language add-ons other than en_gb are shipped as zips for the local language repository.
package 'unzip'

# Droid Sans Fallback in the bundled arial.ttf draws kanji with Chinese glyph forms.
if node[:kodi][:language].start_with?('ja_')
  package 'fonts-noto-cjk' do
    options '--no-install-recommends'
  end
end

# Kodi publishes its services through the Avahi daemon, and systemd-resolved would answer on the same port.
if node[:kodi][:remote]
  package 'avahi-daemon' do
    options '--no-install-recommends'
  end

  directory '/etc/systemd/resolved.conf.d' do
    owner 'root'
    group 'root'
    mode  '0755'
  end

  file '/etc/systemd/resolved.conf.d/kodi-mdns.conf' do
    owner   'root'
    group   'root'
    mode    '0644'
    content <<~__EOF__
      [Resolve]
      MulticastDNS=no
    __EOF__
  end
end

#
# Owner/Group
#

group node[:kodi][:group][:name] do
  gid node[:kodi][:group][:gid]
end

user node[:kodi][:owner][:name] do
  uid         node[:kodi][:owner][:uid]
  gid         node[:kodi][:group][:gid]
  shell       '/usr/sbin/nologin'
  home        node[:kodi][:directory][:path]
  create_home false
  system_user true
end

#
# Directory
#

directory node[:kodi][:directory][:path] do
  owner node[:kodi][:directory][:owner]
  group node[:kodi][:directory][:group]
  mode  node[:kodi][:directory][:mode]
end

#
# Language Add-on
#

%W{
  #{kodi_home}
  #{kodi_home}/addons
}.each do |dir|
  directory dir do
    owner node[:kodi][:owner][:name]
    group node[:kodi][:group][:name]
    mode  '0755'
  end
end

# Kodi enables an installed but disabled language add-on when it is selected.
# The build has no sudo to switch users with, so extract as root and hand the tree to the owner.
execute "unzip -o -d #{kodi_home}/addons /usr/share/kodi/language-repo/#{language_addon}/#{language_addon}-*.zip && chown -R #{node[:kodi][:owner][:name]}:#{node[:kodi][:group][:name]} #{kodi_home}/addons/#{language_addon}" do
  not_if [
    "test -d /usr/share/kodi/addons/#{language_addon}",
    "test -d #{kodi_home}/addons/#{language_addon}",
  ].join(' || ')
end

#
# Skin Font
#

# The skin's Arial font set looks up arial.ttf in the profile's media/Fonts before Kodi's own.
if node[:kodi][:language].start_with?('ja_')
  %W{
    #{kodi_home}/media
    #{kodi_home}/media/Fonts
  }.each do |dir|
    directory dir do
      owner node[:kodi][:owner][:name]
      group node[:kodi][:group][:name]
      mode  '0755'
    end
  end

  # Kodi loads the first face of the collection, which is Noto Sans CJK JP.
  link "#{kodi_home}/media/Fonts/arial.ttf" do
    to '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc'
  end
end

#
# CEC Adapter
#

# Without a CEC capable sink, libcec polls the TV every few seconds and the kernel logs each timeout.
unless node[:kodi][:cec]
  %W{
    #{kodi_home}/userdata
    #{kodi_home}/userdata/peripheral_data
  }.each do |dir|
    directory dir do
      owner node[:kodi][:owner][:name]
      group node[:kodi][:group][:name]
      mode  '0755'
    end
  end

  # Kodi rewrites the file with every adapter setting, and saves its own values when it exits.
  file cec_settings do
    owner   node[:kodi][:owner][:name]
    group   node[:kodi][:group][:name]
    mode    '0644'
    content <<~__EOF__
      <settings>
          <setting id="enabled" value="0"/>
      </settings>
    __EOF__
    not_if "test -e #{cec_settings}"
  end
end

#
# Video Sources
#

unless node[:kodi][:video_sources].empty?
  directory "#{kodi_home}/userdata" do
    owner node[:kodi][:owner][:name]
    group node[:kodi][:group][:name]
    mode  '0755'
  end

  # Kodi rewrites the file when a source is edited, and fills in the other media types.
  template sources_xml do
    owner  node[:kodi][:owner][:name]
    group  node[:kodi][:group][:name]
    mode   '0644'
    source 'templates/sources.xml.erb'
    not_if "test -e #{sources_xml}"
  end
end

#
# Default Settings
#

# Kodi reads appliance-specific setting defaults only from its system directory.
execute "dpkg-divert --local --rename --divert #{appliance_xml}.distrib --add #{appliance_xml}" do
  not_if "test \"$(dpkg-divert --truename #{appliance_xml})\" = #{appliance_xml}.distrib"
end

template appliance_xml do
  owner     'root'
  group     'root'
  mode      '0644'
  source    'templates/appliance.xml.erb'
  variables distrib: "#{appliance_xml}.distrib"
end

#
# Systemd Service
#

template '/etc/systemd/system/kodi.service' do
  owner  'root'
  group  'root'
  mode   '0644'
  source 'templates/systemd.service.erb'
end

service 'kodi.service' do
  action :enable
end
