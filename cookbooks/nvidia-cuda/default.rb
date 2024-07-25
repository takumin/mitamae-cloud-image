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
node[:nvidia_cuda][:origin][:ubuntu][:jammy]    ||= 'https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64'
node[:nvidia_cuda][:origin][:ubuntu][:noble]    ||= 'https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64'
node[:nvidia_cuda][:origin][:debian]            ||= Hashie::Mash.new
node[:nvidia_cuda][:origin][:debian][:bullseye] ||= 'https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64'
node[:nvidia_cuda][:origin][:debian][:bookworm] ||= 'https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64'
node[:nvidia_cuda][:mirror]                     ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:ubuntu]            ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:ubuntu][:jammy]    ||= node[:nvidia_cuda][:origin][:ubuntu][:jammy]
node[:nvidia_cuda][:mirror][:ubuntu][:noble]    ||= node[:nvidia_cuda][:origin][:ubuntu][:noble]
node[:nvidia_cuda][:mirror][:debian]            ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:debian][:bullseye] ||= node[:nvidia_cuda][:origin][:debian][:bullseye]
node[:nvidia_cuda][:mirror][:debian][:bookworm] ||= node[:nvidia_cuda][:origin][:debian][:bookworm]

#
# Override Variables
#

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_JAMMY'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_JAMMY'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:jammy] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_JAMMY']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_NOBLE'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_NOBLE'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:noble] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_NOBLE']
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
          jammy:  match(/^(?:https?|file):\/\//),
          noble:  match(/^(?:https?|file):\/\//),
        },
        debian: {
          bullseye: match(/^(?:https?|file):\/\//),
          bookworm: match(/^(?:https?|file):\/\//),
        },
      },
      mirror: {
        ubuntu: {
          jammy:  match(/^(?:https?|file):\/\//),
          noble:  match(/^(?:https?|file):\/\//),
        },
        debian: {
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
  when '22.04'
    platform_codename = :jammy
  when '24.04'
    platform_codename = :noble
  end
when 'debian'
  case node[:platform_version]
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

package 'xserver-xorg-core'
package 'cuda-drivers'
