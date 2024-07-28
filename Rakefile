# frozen_string_literal: true

require 'fileutils'
require 'open-uri'
require 'open3'
require 'yaml'
require 'json'

PUBLISH_UBUNTU_SUITE = 'noble'
PUBLISH_DEBIAN_SUITE = 'bookworm'

MITAMAE_VERSION = 'v1.14.1'

LOG_LEVEL = ENV['LOG_LEVEL'] || 'info'

DISTRIBUTIONS = [
  'debian',
  'ubuntu',
]

SUITES = {
  'debian' => [
    'bullseye',
    'bookworm',
  ],
  'ubuntu' => [
    'jammy',
    'noble',
  ],
}

KERNELS = {
  'debian' => [
    'generic',
    'generic-backports',
    'cloud',
    'cloud-backports',
    # FIXME: Raspberry Pi Repository Error
    # 'raspberrypi',
  ],
  'ubuntu' => [
    'generic',
    'generic-hwe',
    'virtual',
    'virtual-hwe',
    'raspi',
  ],
}

ROLES = {
  'debian' => [
    'minimal',
    'server',
    'server-nvidia',
    'server-nvidia-cuda',
    'server-nvidia-legacy',
    'desktop',
    'desktop-nvidia',
    'desktop-nvidia-cuda',
    'desktop-nvidia-legacy',
    'desktop-rtl8852au-nvidia-cuda',
  ],
  'ubuntu' => [
    'minimal',
    'server',
    'server-nvidia',
    'server-nvidia-cuda',
    'server-nvidia-legacy',
    'desktop',
    'desktop-nvidia',
    'desktop-nvidia-cuda',
    'desktop-nvidia-legacy',
    'desktop-rtl8852au-nvidia-cuda',
  ],
}

ARCHITECTURES = [
  'amd64',
  'arm64',
]

targets = []

DISTRIBUTIONS.each do |distribution|
  SUITES[distribution].each do |suite|
    KERNELS[distribution].each do |kernel|
      ROLES[distribution].each do |role|
        ARCHITECTURES.each do |architecture|
          next if architecture.match('amd64') and kernel.match(/raspi|raspberrypi/)
          next if !architecture.match('amd64') and role.match(/nvidia/)
          next if !kernel.match(/generic/) and role.match(/nvidia/)

          # Workaround: Because the linux-headers-amd64 dependency is broken in Debian Bullseye
          next if distribution.eql?('debian') and suite.eql?('bullseye') and kernel.match?(/backports/)

          targets << {
            'distribution' => distribution,
            'suite'        => suite,
            'kernel'       => kernel,
            'architecture' => architecture,
            'role'         => role,
          }
        end
      end
    end
  end
end

SUITES['debian'].each do |suite|
  targets << {
    'distribution' => 'debian',
    'suite'        => suite,
    'kernel'       => 'proxmox',
    'architecture' => 'amd64',
    'role'         => 'proxmox-ve',
  }
end

ppa_nvidia_vgpu = true
%w{
  APT_REPO_PPA_NVIDIA_VGPU_KEYRING_UID
  APT_REPO_PPA_NVIDIA_VGPU_KEYRING_FINGER_PRINT
  APT_REPO_PPA_NVIDIA_VGPU_KEYRING_URL
  APT_REPO_PPA_NVIDIA_VGPU_URL
}.each do |k|
  if ENV.key?(k)
    if ENV[k].empty?
      ppa_nvidia_vgpu = false
      break
    end
  end
end

if ppa_nvidia_vgpu
  DISTRIBUTIONS.each do |distribution|
    case distribution
    when 'debian'
      suite  = 'bookworm'
      kernel = 'generic'
    when 'ubuntu'
      suite  = 'noble'
      kernel = 'generic-hwe'
    else
      next
    end

    targets << {
      'distribution' => distribution,
      'suite'        => suite,
      'kernel'       => kernel,
      'architecture' => 'amd64',
      'role'         => 'server-nvidia-vgpu',
    }
  end
end

targets.each do |target|
  namespace target.values.join(':') do
    task :initialize do
      setup_mitamae
      setup_profile(target)

      cmd = [
        'sudo', '-E',
        './.bin/mitamae', 'local',
        '-l', LOG_LEVEL,
        '-y', './.bin/profile.yaml',
        './phases/initialize.rb',
      ].join(' ')

      unless execution(cmd)
        abort('failed command')
      end
    end

    task :provision do
      target_dir  = ENV['TARGET_DIRECTORY'] || "/tmp/#{target.values.join('-')}"

      cmd = [
        'sudo', 'rsync', '-a',
        '--exclude=".git/"',
        '--exclude="releases/"',
        "#{File.expand_path(__dir__)}/",
        "#{File.join(target_dir, 'mitamae')}/"
      ].join(' ')

      unless execution(cmd)
        abort('failed command')
      end

      cmd = [
        'sudo', '-E', 'chroot', target_dir,
        'mitamae', 'local',
        '-l', LOG_LEVEL,
        '-y', '/mitamae/.bin/profile.yaml',
        '--plugins=/mitamae/plugins',
        '/mitamae/phases/provision.rb',
      ].join(' ')

      unless execution(cmd)
        abort('failed command')
      end

      unless execution("sudo rm -fr #{File.join(target_dir, 'mitamae')}")
        abort('failed command')
      end
    end

    task :finalize do
      cmd = [
        'sudo', '-E',
        './.bin/mitamae', 'local',
        '-l', LOG_LEVEL,
        '-y', './.bin/profile.yaml',
        './phases/finalize.rb',
      ].join(' ')

      unless execution(cmd)
        abort('failed command')
      end

      unless execution("find #{File.expand_path(File.join(__dir__, 'releases'))} -type d | xargs sudo chmod 0755")
        abort('failed command')
      end

      unless execution("find #{File.expand_path(File.join(__dir__, 'releases'))} -type f | xargs sudo chmod 0644")
        abort('failed command')
      end

      unless execution("sudo chown -R $(id -u):$(id -g) #{File.expand_path(File.join(__dir__, 'releases'))}")
        abort('failed command')
      end
    end

    desc target.values.join(' ')
    task :all => [
      :initialize,
      :provision,
      :finalize,
    ]
  end
end

namespace :github do
  namespace :actions do
    task :all do
      # NOTE: Unused NVIDIA Legacy Version
      targets.delete_if{|v| v.values.include?('server-nvidia-legacy')}
      targets.delete_if{|v| v.values.include?('desktop-nvidia-legacy')}
      # TODO: GitHub Actions Once the arm64 runner is GA, remove the following
      targets.delete_if{|v| v.values.include?('arm64')}
      # FIXME: install error nvidia-vgpu-dkms 535.129.03
      targets.delete_if{|v| v.values.include?('ubuntu') && v.values.include?('noble') && v.values.include?('server-nvidia-vgpu')}

      puts JSON.dump(targets.map{|v|
        {
          name: v.values.join(':'),
          dir:  v.values.join('/'),
        }
      })
    end

    targets.map{|v|
      task "publish:#{v.values.join(':')}" do
        publish = false

        if v['distribution'].eql?('ubuntu')
          if v['suite'].eql?(PUBLISH_UBUNTU_SUITE)
            if v['kernel'].match?(/^(generic|virtual)-hwe$/)
              publish = true
            end
          end
        end

        if v['distribution'].eql?('debian')
          if v['suite'].eql?(PUBLISH_DEBIAN_SUITE)
            if v['kernel'].match?(/^(generic|cloud)$/)
              publish = true
            end
          end
        end

        puts "PUBLISH=#{publish}"
      end
    }
  end
end

def setup_profile(target)
  dir = File.expand_path('.bin', __dir__)
  yaml = File.join(dir, 'profile.yaml')
  data = { 'target' => target }
  if target['kernel'].match(/raspi|raspberrypi/)
    data['autologin'] = {
      'miniuart-bt' => {
        'service' => 'serial-getty',
        'getty'   => '/sbin/agetty',
        'port'    => 'ttyAMA0',
        'user'    => 'root',
        'term'    => 'linux',
        'baud'    => [115200,38400,9600],
        'opts'    => ['--keep-baud', '--flow-control'],
      }
    }
  end
  File.open(yaml, 'w') do |file|
    YAML.dump(data, file)
  end
end

def setup_mitamae
  dir = File.expand_path('.bin', __dir__)
  bin = File.join(dir, 'mitamae')
  url = "https://github.com/itamae-kitchen/mitamae/releases/download/#{MITAMAE_VERSION}/mitamae-x86_64-linux"

  unless Dir.exist?(dir)
    Dir.mkdir(dir)
  end

  if File.exist?(bin)
    if FileTest.executable?(bin)
      begin
        unless `#{bin} version`.match(MITAMAE_VERSION)
          File.delete(bin)
        end
      rescue
        File.delete(bin)
      end
    else
      File.delete(bin)
    end
  end

  unless File.exist?(bin)
    File.open(bin, 'wb') do |file|
      URI.open(url) do |data|
        file.puts data.read
      end
    end
  end

  unless FileTest.executable?(bin)
    FileUtils.chmod(0755, bin)
  end
end

def execution(cmd)
  retval = false

  # https://ikm.hatenablog.jp/entry/2014/11/12/003925
  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    stdin.close_write

    begin
      loop do
        IO.select([stdout, stderr]).flatten.compact.each do |io|
          io.each do |line|
            next if line.nil? || line.empty?
            puts line
          end
        end
        break if stdout.eof? && stderr.eof?
      end
    rescue EOFError
    end

    retval = wait_thr.value.success?
  end

  return retval
end
