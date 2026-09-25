#
# Apt Keyring
#

directory '/usr/share/keyrings' do
  owner 'root'
  group 'root'
  mode '0755'
end

http_request '/usr/share/keyrings/raspberrypi-archive-keyring.gpg' do
  url 'https://github.com/raspberrypi/rpi-image-gen/raw/refs/heads/master/keydir/raspberrypi-archive-keyring.gpg'
  owner 'root'
  group 'root'
  mode '0644'
  not_if 'test -e /usr/share/keyrings/raspberrypi-archive-keyring.gpg'
end

#
# Apt Repository
#

apt_repository 'Raspberry Pi OS Repository' do
  path '/etc/apt/sources.list.d/raspberrypi.list'
  header [
    '#',
    '# Raspberry Pi OS Repository',
    '#',
  ]
  entry [
    {
      :default_uri => 'http://archive.raspberrypi.org/debian',
      :mirror_uri  => "#{ENV['APT_REPO_URL_RASPBERRYPI']}",
      :suite       => '###platform_codename###',
      :options     => 'signed-by=/usr/share/keyrings/raspberrypi-archive-keyring.gpg',
      :components  => ['main'],
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
# Repository Keyring
#

package 'raspberrypi-archive-keyring'

#
# Raspberry Pi Tools
#

package 'raspi-firmware'
package 'raspi-utils-core'
package 'bluez-firmware'
package 'firmware-brcm80211'
