# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match?(/-nvidia-vgpu$/)
  return
end

#
# Check Architecture
#

unless node[:target][:architecture].match?(/(?:amd64)$/)
  MItamae.logger.error "nvidia-vgpu: Unsupported architecture: #{node[:kernel][:machine]}"
  exit 1
end

#
# Check Platform
#

unless node[:platform].match?(/(?:debian|ubuntu)$/)
  MItamae.logger.error "nvidia-vgpu: Unsupported platform: #{node[:platform]}"
  exit 1
end

#
# Check Environment Variables
#

%w{
  APT_REPO_PPA_NVIDIA_VGPU_KEYRING_UID
  APT_REPO_PPA_NVIDIA_VGPU_KEYRING_FINGER_PRINT
  APT_REPO_PPA_NVIDIA_VGPU_KEYRING_URL
  APT_REPO_PPA_NVIDIA_VGPU_URL
}.each do |k|
  if !ENV.key?(k) or ENV[k].empty?
    MItamae.logger.error "nvidia-vgpu: Required environment variables: #{k}"
    exit 1
  end
end

#
# Apt Keyring
#

directory '/etc/apt/keyrings' do
  owner 'root'
  group 'root'
  mode '0755'
end

http_request '/etc/apt/keyrings/nvidia-vgpu.gpg.asc' do
  url ENV['APT_REPO_PPA_NVIDIA_VGPU_KEYRING_URL']
  owner 'root'
  group 'root'
  mode '0644'
  not_if 'test -e /etc/apt/keyrings/nvidia-vgpu.gpg.asc'
end

#
# Apt Repository
#

apt_repository 'PPA NVIDIA vGPU Repository' do
  path '/etc/apt/sources.list.d/nvidia-vgpu.list'
  entry [
    {
      :default_uri => ENV['APT_REPO_PPA_NVIDIA_VGPU_URL'],
      :options     => 'signed-by=/etc/apt/keyrings/nvidia-vgpu.gpg.asc',
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
# Required Packages
#

include_recipe File.expand_path('../linux-headers', File.dirname(__FILE__))

package 'build-essential'
package 'dkms'

#
# Install Package
#

package 'nvidia-vgpu'

#
# Enable Services
#

%w{nvidia-vgpu-mgr.service nvidia-vgpud.service}.each do |s|
  service s do
    action :enable
  end
end
