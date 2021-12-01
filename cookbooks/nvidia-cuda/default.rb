# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match?(/-nvidia-cuda$/)
  return
end

#
# Check Distribution
#

unless node[:target][:distribution].match?(/^ubuntu$/)
  return
end

#
# Check Architecture
#

unless node[:kernel][:machine].match?(/^x86_64$/)
  return
end

#
# Public Variables
#

node[:nvidia_cuda]                            ||= Hashie::Mash.new
node[:nvidia_cuda][:origin]                   ||= Hashie::Mash.new
node[:nvidia_cuda][:origin][:ubuntu]          ||= Hashie::Mash.new
node[:nvidia_cuda][:origin][:ubuntu][:xenial] ||= 'http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64'
node[:nvidia_cuda][:origin][:ubuntu][:bionic] ||= 'http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64'
node[:nvidia_cuda][:origin][:ubuntu][:focal]  ||= 'http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64'
node[:nvidia_cuda][:mirror]                   ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:ubuntu]          ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:ubuntu][:xenial] ||= node[:nvidia_cuda][:origin][:ubuntu][:xenial]
node[:nvidia_cuda][:mirror][:ubuntu][:bionic] ||= node[:nvidia_cuda][:origin][:ubuntu][:bionic]
node[:nvidia_cuda][:mirror][:ubuntu][:focal]  ||= node[:nvidia_cuda][:origin][:ubuntu][:focal]

#
# Override Variables
#

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_XENIAL'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_XENIAL'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:xenial] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_XENIAL']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_BIONIC'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_BIONIC'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:bionic] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_BIONIC']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_FOCAL'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_FOCAL'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:focal] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_FOCAL']
end

#
# Validate Variables
#

node.validate! do
  {
    nvidia_cuda: {
      origin: {
        ubuntu: {
          xenial: match(/^(?:https?|file):\/\//),
          bionic: match(/^(?:https?|file):\/\//),
          focal:  match(/^(?:https?|file):\/\//),
        },
      },
      mirror: {
        ubuntu: {
          xenial: match(/^(?:https?|file):\/\//),
          bionic: match(/^(?:https?|file):\/\//),
          focal:  match(/^(?:https?|file):\/\//),
        },
      },
    },
  }
end

#
# Private Variables
#

case node[:platform_version]
when '16.04'
  platform_codename = :xenial
when '18.04'
  platform_codename = :bionic
when '20.04'
  platform_codename = :focal
end

nvidia_cuda_origin = node[:nvidia_cuda][:origin][node[:platform]][platform_codename]
nvidia_cuda_mirror = node[:nvidia_cuda][:mirror][node[:platform]][platform_codename]

#
# Apt Keyring
#

apt_keyring 'cudatools <cudatools@nvidia.com>' do
  finger 'AE09FE4BBD223A84B2CCFCE3F60F4B3D7FA2AF80'
  uri File.join(nvidia_cuda_origin, '7fa2af80.pub')
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
when 'ubuntu-16.04-generic-hwe'
  package 'xserver-xorg-hwe-16.04'
when 'ubuntu-18.04-generic-hwe'
  package 'xserver-xorg-hwe-18.04'
when 'ubuntu-20.04-generic-hwe'
  # 2020/12/28: X.org HWE package does not exist
else
  package 'xserver-xorg-core'
end

package 'cuda-drivers'
