# frozen_string_literal: true

#
# Public Variables
#

node[:nvidia_cuda]                             ||= Hashie::Mash.new
node[:nvidia_cuda][:origin]                    ||= Hashie::Mash.new
node[:nvidia_cuda][:origin][:ubuntu]           ||= Hashie::Mash.new
node[:nvidia_cuda][:origin][:ubuntu][:precise] ||= 'http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1204'
node[:nvidia_cuda][:origin][:ubuntu][:trusty]  ||= 'http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404'
node[:nvidia_cuda][:origin][:ubuntu][:xenial]  ||= 'http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604'
node[:nvidia_cuda][:origin][:ubuntu][:bionic]  ||= 'http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804'
node[:nvidia_cuda][:mirror]                    ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:ubuntu]           ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:ubuntu][:precise] ||= node[:nvidia_cuda][:origin][:ubuntu][:precise]
node[:nvidia_cuda][:mirror][:ubuntu][:trusty]  ||= node[:nvidia_cuda][:origin][:ubuntu][:trusty]
node[:nvidia_cuda][:mirror][:ubuntu][:xenial]  ||= node[:nvidia_cuda][:origin][:ubuntu][:xenial]
node[:nvidia_cuda][:mirror][:ubuntu][:bionic]  ||= node[:nvidia_cuda][:origin][:ubuntu][:bionic]

#
# Override Variables
#

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_PRECISE'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_PRECISE'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:precise] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_PRECISE']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_TRUSTY'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_TRUSTY'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:trusty] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_TRUSTY']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_XENIAL'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_XENIAL'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:xenial] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_XENIAL']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_BIONIC'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_BIONIC'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:bionic] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_BIONIC']
end

#
# Validate Variables
#

node.validate! do
  {
    nvidia_cuda: {
      origin: {
        ubuntu: {
          precise: match(/^(?:https?|file):\/\//),
          trusty:  match(/^(?:https?|file):\/\//),
          xenial:  match(/^(?:https?|file):\/\//),
          bionic:  match(/^(?:https?|file):\/\//),
        },
      },
      mirror: {
        ubuntu: {
          precise: match(/^(?:https?|file):\/\//),
          trusty:  match(/^(?:https?|file):\/\//),
          xenial:  match(/^(?:https?|file):\/\//),
          bionic:  match(/^(?:https?|file):\/\//),
        },
      },
    },
  }
end

#
# Check Platform
#

unless node[:target][:role].match(/nvidia/)
  return
end

if node[:kernel][:machine] != 'x86_64'
  return
end

case node.platform
when 'ubuntu'
  case node.platform_version
  when '12.04'
    node[:platform_codename] = :precise
  when '14.04'
    node[:platform_codename] = :trusty
  when '16.04'
    node[:platform_codename] = :xenial
  when '18.04'
    node[:platform_codename] = :bionic
  else
    return
  end
else
  return
end

#
# Private Variables
#

nvidia_cuda_origin = node[:nvidia_cuda][:origin][node[:platform]][node[:platform_codename]]
nvidia_cuda_mirror = node[:nvidia_cuda][:mirror][node[:platform]][node[:platform_codename]]

#
# Apt Keyring
#

apt_keyring 'cudatools <cudatools@nvidia.com>' do
  finger 'AE09FE4BBD223A84B2CCFCE3F60F4B3D7FA2AF80'
end

#
# Apt Repository
#

apt_repository '/etc/apt/sources.list.d/nvidia-cuda.list' do
  header [
    '#',
    '# NVIDIA CUDA Repository',
    '#',
  ]
  entry [
    {
      :default_uri => nvidia_cuda_origin,
      :mirror_uri  => nvidia_cuda_mirror,
      :suite       => '/',
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
# Package Install
#

case "#{node[:platform]}-#{node[:platform_version]}-#{node[:target][:kernel]}"
when /^ubuntu-(?:12|14|16|18)\.04-(?:generic|virtual)$/
  package 'xserver-xorg-core'
when /^ubuntu-12\.04-(?:generic|virtual)-latest$/
  package 'xserver-xorg-lts-trusty'
when /^ubuntu-14\.04-(?:generic|virtual)-latest$/
  package 'xserver-xorg-core-lts-xenial'
when /^ubuntu-16\.04-(?:generic|virtual)-latest$/
  package 'xserver-xorg-core-hwe-16.04'
when /^ubuntu-18\.04-(?:generic|virtual)-latest$/
  package 'xserver-xorg-core-hwe-18.04'
end

package 'cuda-drivers'
