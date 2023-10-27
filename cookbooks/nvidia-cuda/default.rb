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

unless node[:target][:distribution].match?(/^(?:ubuntu|debian)$/)
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

node[:nvidia_cuda]                              ||= Hashie::Mash.new
node[:nvidia_cuda][:origin]                     ||= Hashie::Mash.new
node[:nvidia_cuda][:origin][:ubuntu]            ||= Hashie::Mash.new
node[:nvidia_cuda][:origin][:ubuntu][:bionic]   ||= 'https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64'
node[:nvidia_cuda][:origin][:ubuntu][:focal]    ||= 'https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64'
node[:nvidia_cuda][:origin][:ubuntu][:jammy]    ||= 'https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64'
node[:nvidia_cuda][:origin][:debian]            ||= Hashie::Mash.new
node[:nvidia_cuda][:origin][:debian][:buster]   ||= 'https://developer.download.nvidia.com/compute/cuda/repos/debian10/x86_64'
node[:nvidia_cuda][:origin][:debian][:bullseye] ||= 'https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64'
node[:nvidia_cuda][:origin][:debian][:bookworm] ||= 'https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64'
node[:nvidia_cuda][:mirror]                     ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:ubuntu]            ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:ubuntu][:bionic]   ||= node[:nvidia_cuda][:origin][:ubuntu][:bionic]
node[:nvidia_cuda][:mirror][:ubuntu][:focal]    ||= node[:nvidia_cuda][:origin][:ubuntu][:focal]
node[:nvidia_cuda][:mirror][:ubuntu][:jammy]    ||= node[:nvidia_cuda][:origin][:ubuntu][:jammy]
node[:nvidia_cuda][:mirror][:debian]            ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:debian][:buster]   ||= node[:nvidia_cuda][:origin][:debian][:buster]
node[:nvidia_cuda][:mirror][:debian][:bullseye] ||= node[:nvidia_cuda][:origin][:debian][:bullseye]
node[:nvidia_cuda][:mirror][:debian][:bookworm] ||= node[:nvidia_cuda][:origin][:debian][:bookworm]

#
# Override Variables
#

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_BIONIC'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_BIONIC'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:bionic] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_BIONIC']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_FOCAL'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_FOCAL'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:focal] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_FOCAL']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_JAMMY'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_JAMMY'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:jammy] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_JAMMY']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BUSTER'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BUSTER'].empty?
  node[:nvidia_cuda][:mirror][:debian][:buster] = ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BUSTER']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BULLSEYE'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BULLSEYE'].empty?
  node[:nvidia_cuda][:mirror][:debian][:bullseye] = ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BULLSEYE']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BOOKWORM'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BOOKWORM'].empty?
  node[:nvidia_cuda][:mirror][:debian][:bookworm] = ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BOOKWORM']
end

#
# Validate Variables
#

node.validate! do
  {
    nvidia_cuda: {
      origin: {
        ubuntu: {
          bionic: match(/^(?:https?|file):\/\//),
          focal:  match(/^(?:https?|file):\/\//),
          jammy:  match(/^(?:https?|file):\/\//),
        },
        debian: {
          buster:   match(/^(?:https?|file):\/\//),
          bullseye: match(/^(?:https?|file):\/\//),
          bookworm: match(/^(?:https?|file):\/\//),
        },
      },
      mirror: {
        ubuntu: {
          bionic: match(/^(?:https?|file):\/\//),
          focal:  match(/^(?:https?|file):\/\//),
          jammy:  match(/^(?:https?|file):\/\//),
        },
        debian: {
          buster:   match(/^(?:https?|file):\/\//),
          bullseye: match(/^(?:https?|file):\/\//),
          bookworm: match(/^(?:https?|file):\/\//),
        },
      },
    },
  }
end

#
# Private Variables
#

case node[:platform]
when 'ubuntu'
  case node[:platform_version]
  when '18.04'
    platform_codename = :bionic
  when '20.04'
    platform_codename = :focal
  when '22.04'
    platform_codename = :jammy
  end
when 'debian'
  case node[:platform_version]
  when /^10/
    platform_codename = :buster
  when /^11/
    platform_codename = :bullseye
  when /^12/
    platform_codename = :bookworm
  end
end

nvidia_cuda_origin = node[:nvidia_cuda][:origin][node[:platform]][platform_codename]
nvidia_cuda_mirror = node[:nvidia_cuda][:mirror][node[:platform]][platform_codename]

#
# HTTPS Apt Repository
#

package 'apt-transport-https'

#
# Apt Keyring
#

apt_keyring 'cudatools <cudatools@nvidia.com>' do
  finger 'EB693B3035CD5710E231E123A4B469963BF863CC'
  uri File.join(nvidia_cuda_origin, '3bf863cc.pub')
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
when 'ubuntu-18.04-generic-hwe'
  package 'xserver-xorg-hwe-18.04'
else
  package 'xserver-xorg-core'
end

package 'cuda-drivers'
