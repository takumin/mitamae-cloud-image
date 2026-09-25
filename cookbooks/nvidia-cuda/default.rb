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
node[:nvidia_cuda][:origin][:ubuntu][:noble]    ||= 'https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64'
node[:nvidia_cuda][:origin][:ubuntu][:resolute] ||= 'https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2604/x86_64'
node[:nvidia_cuda][:origin][:debian]            ||= Hashie::Mash.new
node[:nvidia_cuda][:origin][:debian][:bookworm] ||= 'https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64'
node[:nvidia_cuda][:origin][:debian][:trixie]   ||= 'https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64'
node[:nvidia_cuda][:mirror]                     ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:ubuntu]            ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:ubuntu][:noble]    ||= node[:nvidia_cuda][:origin][:ubuntu][:noble]
node[:nvidia_cuda][:mirror][:ubuntu][:resolute] ||= node[:nvidia_cuda][:origin][:ubuntu][:resolute]
node[:nvidia_cuda][:mirror][:debian]            ||= Hashie::Mash.new
node[:nvidia_cuda][:mirror][:debian][:bookworm] ||= node[:nvidia_cuda][:origin][:debian][:bookworm]
node[:nvidia_cuda][:mirror][:debian][:trixie]   ||= node[:nvidia_cuda][:origin][:debian][:trixie]

#
# Override Variables
#

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_NOBLE'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_NOBLE'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:noble] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_NOBLE']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_RESOLUTE'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_RESOLUTE'].empty?
  node[:nvidia_cuda][:mirror][:ubuntu][:resolute] = ENV['APT_REPO_URL_NVIDIA_CUDA_UBUNTU_RESOLUTE']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BOOKWORM'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BOOKWORM'].empty?
  node[:nvidia_cuda][:mirror][:debian][:bookworm] = ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_BOOKWORM']
end

if ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_TRIXIE'].is_a?(String) and !ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_TRIXIE'].empty?
  node[:nvidia_cuda][:mirror][:debian][:trixie] = ENV['APT_REPO_URL_NVIDIA_CUDA_DEBIAN_TRIXIE']
end

#
# Validate Variables
#

node.validate! do
  {
    nvidia_cuda: {
      origin: {
        ubuntu: {
          noble:    match(/^(?:https?|file):\/\//),
          resolute: match(/^(?:https?|file):\/\//),
        },
        debian: {
          bookworm: match(/^(?:https?|file):\/\//),
          trixie:   match(/^(?:https?|file):\/\//),
        },
      },
      mirror: {
        ubuntu: {
          noble:    match(/^(?:https?|file):\/\//),
          resolute: match(/^(?:https?|file):\/\//),
        },
        debian: {
          bookworm: match(/^(?:https?|file):\/\//),
          trixie:   match(/^(?:https?|file):\/\//),
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
  when '24.04'
    platform_codename   = :noble
    signing_key         = '3bf863cc.pub'
    signing_key_fpr     = 'EB693B3035CD5710E231E123A4B469963BF863CC'
    signing_key_user_id = 'cudatools <cudatools@nvidia.com>'
  when '26.04'
    platform_codename   = :resolute
    signing_key         = '60DF8A40.pub'
    signing_key_fpr     = '14BAFBC7562AD710CA04E69905FBB6DA60DF8A40'
    signing_key_user_id = 'Kitmaker (Ubuntu 26.04) <kitmaker@nvidia.com>'
  end
when 'debian'
  case node[:platform_version]
  when /^12/
    platform_codename   = :bookworm
    signing_key         = '3bf863cc.pub'
    signing_key_fpr     = 'EB693B3035CD5710E231E123A4B469963BF863CC'
    signing_key_user_id = 'cudatools <cudatools@nvidia.com>'
  when /^13/
    platform_codename   = :trixie
    signing_key         = '8793F200.pub'
    signing_key_fpr     = '02182E60104FCDC26EAE1B8597A5D4CB8793F200'
    signing_key_user_id = 'Kitmaker (Debian 13 Trixie) <kitmaker@nvidia.com>'
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

directory '/etc/apt/keyrings' do
  owner 'root'
  group 'root'
  mode '0755'
end

gpg_keyring '/etc/apt/keyrings/nvidia-cuda.gpg.asc' do
  fingerprint signing_key_fpr
  user_id     signing_key_user_id
  url         File.join(nvidia_cuda_origin, signing_key)
  owner       'root'
  group       'root'
  mode        '0644'
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
      :options     => 'signed-by=/etc/apt/keyrings/nvidia-cuda.gpg.asc',
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
