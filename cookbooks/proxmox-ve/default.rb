# frozen_string_literal: true

#
# Check Role
#

unless node.target.role.match?(/proxmox-ve/)
  return
end

#
# Public Variables
#

node[:proxmox_ve]                                   ||= Hashie::Mash.new
node[:proxmox_ve][:subscription]                    ||= false
node[:proxmox_ve][:apt]                             ||= Hashie::Mash.new
node[:proxmox_ve][:apt][:url]                       ||= Hashie::Mash.new
node[:proxmox_ve][:apt][:url][:origin]              ||= Hashie::Mash.new
node[:proxmox_ve][:apt][:url][:origin][:enterprise] ||= 'https://enterprise.proxmox.com/debian/pve'
node[:proxmox_ve][:apt][:url][:origin][:community]  ||= 'http://download.proxmox.com/debian/pve'
node[:proxmox_ve][:apt][:url][:mirror]              ||= Hashie::Mash.new
node[:proxmox_ve][:apt][:url][:mirror][:enterprise] ||= 'https://enterprise.proxmox.com/debian/pve'
node[:proxmox_ve][:apt][:url][:mirror][:community]  ||= 'http://download.proxmox.com/debian/pve'
node[:proxmox_ve][:apt][:components]                ||= Hashie::Mash.new
node[:proxmox_ve][:apt][:components][:enterprise]   ||= ['pve-enterprise']
node[:proxmox_ve][:apt][:components][:community]    ||= ['pve-no-subscription']
node[:proxmox_ve][:keyring]                         ||= Hashie::Mash.new
node[:proxmox_ve][:keyring][:bullseye]              ||= Hashie::Mash.new
node[:proxmox_ve][:keyring][:bullseye][:uid]        ||= 'Proxmox Bullseye Release Key <proxmox-release@proxmox.com>'
node[:proxmox_ve][:keyring][:bullseye][:fpr]        ||= '28139A2F830BD68478A1A01FDD4BA3917E23BF59'
node[:proxmox_ve][:keyring][:bullseye][:url]        ||= 'https://enterprise.proxmox.com/debian/proxmox-release-bullseye.gpg'
node[:proxmox_ve][:keyring][:bookworm]              ||= Hashie::Mash.new
node[:proxmox_ve][:keyring][:bookworm][:uid]        ||= 'Proxmox Bookworm Release Key <proxmox-release@proxmox.com>'
node[:proxmox_ve][:keyring][:bookworm][:fpr]        ||= 'F4E136C67CDCE41AE6DE6FC81140AF8F639E0C39'
node[:proxmox_ve][:keyring][:bookworm][:url]        ||= 'https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg'

#
# Default Variables
#

if ENV['APT_REPO_URL_PROXMOX_VE_ENTERPRISE'].is_a?(String) and !ENV['APT_REPO_URL_PROXMOX_VE_ENTERPRISE'].empty?
  node[:proxmox_ve][:apt][:url][:mirror][:enterprise] = ENV['APT_REPO_URL_PROXMOX_VE_ENTERPRISE']
end

if ENV['APT_REPO_URL_PROXMOX_VE_COMMUNITY'].is_a?(String) and !ENV['APT_REPO_URL_PROXMOX_VE_COMMUNITY'].empty?
  node[:proxmox_ve][:apt][:url][:mirror][:community] = ENV['APT_REPO_URL_PROXMOX_VE_COMMUNITY']
end

#
# Validate Variables
#

node.validate! do
  {
    proxmox_ve: {
      subscription: boolean,
      apt: {
        url: {
          origin: {
            enterprise: match(/^(?:https?|file):\/\//),
            community:  match(/^(?:https?|file):\/\//),
          },
          mirror: {
            enterprise: match(/^(?:https?|file):\/\//),
            community:  match(/^(?:https?|file):\/\//),
          },
        },
        components: {
          enterprise: array_of(string),
          community:  array_of(string),
        },
      },
      keyring: {
        bullseye: {
          uid: string,
          fpr: string,
          url: match(/^(?:https?|file):\/\//),
        },
        bookworm: {
          uid: string,
          fpr: string,
          url: match(/^(?:https?|file):\/\//),
        },
      },
    },
  }
end

#
# Private Variables
#

keyring_uid = node[:proxmox_ve][:keyring][node[:target][:suite]][:uid]
keyring_fpr = node[:proxmox_ve][:keyring][node[:target][:suite]][:fpr]
keyring_url = node[:proxmox_ve][:keyring][node[:target][:suite]][:url]

if node[:proxmox_ve][:subscription]
  apt_origin_url = node[:proxmox_ve][:apt][:url][:origin][:enterprise]
  apt_mirror_url = node[:proxmox_ve][:apt][:url][:mirror][:enterprise]
  apt_components = node[:proxmox_ve][:apt][:components][:enterprise]
else
  apt_origin_url = node[:proxmox_ve][:apt][:url][:origin][:community]
  apt_mirror_url = node[:proxmox_ve][:apt][:url][:mirror][:community]
  apt_components = node[:proxmox_ve][:apt][:components][:community]
end

#
# Proxmox VE Non Subscription Repository
#

apt_keyring keyring_uid do
  finger keyring_fpr
  uri keyring_url
end

#
# Proxmox VE Non Subscription Repository
#

apt_repository 'Proxmox VE Repository' do
  path '/etc/apt/sources.list.d/proxmox-ve.list'
  entry [
    {
      :default_uri => apt_origin_url,
      :mirror_uri  => apt_mirror_url,
      :suite       => node[:target][:suite],
      :components  => apt_components,
    },
  ]
  notifies :run, 'execute[apt-get update]', :immediately
end

#
# Apt Handler
#

execute 'apt-get update' do
  action :nothing
end

#
# Set Proxmox Install Mode
#

file '/proxmox_install_mode' do
  action :create
end

#
# Required Packages
#

package 'cpio'

#
# Proxmox VE Packages
#

package 'proxmox-archive-keyring'
package 'pve-manager'
package 'pve-qemu-kvm'
package 'qemu-server'

#
# Unset Proxmox Install Mode
#

file '/proxmox_install_mode' do
  action :delete
end

#
# TODO: Admin User Management
#
