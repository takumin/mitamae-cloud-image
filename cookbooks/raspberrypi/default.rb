# frozen_string_literal: true

#
# Check Distribution
#

unless node[:target][:distribution].match(/^(?:debian|ubuntu)$/)
  return
end

#
# Check Kernel
#

unless node[:target][:kernel].match(/^(?:raspberrypi|raspi)$/)
  return
end

#
# Raspberry Pi Official Repository
#

if node[:target][:distribution].match(/^debian$/)
  #
  # Apt Keyrings
  #

  apt_keyring 'Raspberry Pi Archive Signing Key' do
    finger 'CF8A1AF502A2AA2D763BAE7E82B129927FA3303E'
    uri 'https://archive.raspberrypi.org/debian/raspberrypi.gpg.key'
  end

  #
  # Apt Repository
  #

  apt_repository 'Raspberry Pi Repository' do
    path '/etc/apt/sources.list.d/raspi.list'
    entry [
      {
        :default_uri => 'http://archive.raspberrypi.org/debian',
        :mirror_uri  => "#{ENV['APT_REPO_URL_RASPBERRYPI']}",
        :suite       => '###platform_codename###',
        :components  => [
          'main',
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
  # Repository Keyring
  #

  package 'raspberrypi-archive-keyring'

  #
  # Remove Old Keyring
  #

  file '/etc/apt/trusted.gpg' do
    action :delete
  end
end

#
# Raspberry Pi Tools
#

package 'libraspberrypi-bin'
