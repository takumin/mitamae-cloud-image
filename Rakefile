# frozen_string_literal: true

require 'fileutils'
require 'open-uri'
require 'open3'
require 'yaml'

MITAMAE_VERSION = 'v1.12.9'

LOG_LEVEL = ENV['LOG_LEVEL'] || 'info'

DISTRIBUTIONS = [
  'debian',
  'ubuntu',
]

SUITES = {
  'debian' => [
    'stretch',
    'buster',
    'bullseye',
  ],
  'ubuntu' => [
    'bionic',
    'focal',
    'jammy',
  ],
}

KERNELS = {
  'debian' => [
    'generic',
    'virtual',
  ],
  'ubuntu' => [
    'generic',
    'generic-hwe',
    'virtual',
    'virtual-hwe',
  ],
}

ROLES = {
  'debian' => [
    'minimal',
    'server',
    'desktop',
  ],
  'ubuntu' => [
    'minimal',
    'server',
    'server-nvidia',
    'desktop',
    'desktop-nvidia',
  ],
}

ARCHITECTURES = [
  'amd64',
  'arm64',
]

DISTRIBUTIONS.each do |distribution|
  SUITES[distribution].each do |suite|
    KERNELS[distribution].each do |kernel|
      ROLES[distribution].each do |role|
        ARCHITECTURES.each do |architecture|
          target = {
            'distribution' => distribution,
            'suite'        => suite,
            'kernel'       => kernel,
            'architecture' => architecture,
            'role'         => role,
          }

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

              unless execution("sudo chown -R $(id -u):$(id -g) #{File.expand_path(__dir__)}")
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
      end
    end
  end
end

def setup_profile(target)
  dir = File.expand_path('.bin', __dir__)
  yaml = File.join(dir, 'profile.yaml')
  data = { 'target' => target }
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
