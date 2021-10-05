require 'fileutils'
require 'open-uri'
require 'open3'
require 'yaml'

mitamae_path = File.join(Dir.pwd, '.bin', 'mitamae')

unless Dir.exist?(File.dirname(mitamae_path))
  Dir.mkdir(File.dirname(mitamae_path))
end

unless File.exist?(mitamae_path)
  File.open(mitamae_path, 'wb') do |file|
    open('https://github.com/itamae-kitchen/mitamae/releases/download/v1.12.7/mitamae-x86_64-linux') do |bin|
      file.puts bin.read
    end
  end
end

unless FileTest.executable?(mitamae_path)
  FileUtils.chmod(0755, mitamae_path)
end

profiles = []
profiles.concat(Dir.glob('**/*.yml', base: File.join(Dir.pwd, 'profiles')))
profiles.concat(Dir.glob('**/*.yaml', base: File.join(Dir.pwd, 'profiles')))
profiles.each do |profile|
  profile_name = profile.gsub(/\//, '_').gsub(/\.ya?ml$/, '')
  profile_path = File.join(Dir.pwd, 'profiles', profile)
  profile_yaml = YAML.load_file(profile_path)

  if ENV['TARGET_DIRECTORY']
    target_dir = ENV['TARGET_DIRECTORY']
  elsif profile_yaml['target']['directory']
    target_dir = profile_yaml['target']['directory']
  else
    raise
  end

  namespace profile_name do
    desc 'initialize'
    task :initialize do
      recipe_path  = File.join(Dir.pwd, 'phases', 'initialize.rb')

      unless execution(['sudo', '-E', mitamae_path, 'local', '-y', profile_path, recipe_path].join(' '))
        abort('failed command')
      end
    end

    desc 'provision'
    task :provision do
      mitamae_dir  = File.join(target_dir, 'mitamae')
      recipe_path  = File.join('/mitamae', 'phases', 'provision.rb')
      exclude_list = ['--exclude=".git/"', '--exclude="releases/"']

      unless execution(['sudo', 'rsync', '-av', exclude_list.join(' '), "#{Dir.pwd}/", "#{mitamae_dir}/"].join(' '))
        abort('failed command')
      end

      unless execution([
        'sudo', '-E', 'chroot', target_dir,
        'mitamae', 'local',
        '--plugins=/mitamae/plugins',
        '-y', "/mitamae/profiles/#{profile}",
        recipe_path
      ].join(' '))
        abort('failed command')
      end

      unless execution(['sudo', 'rm', '-fr', File.join(target_dir, 'mitamae')].join(' '))
        abort('failed command')
      end
    end

    desc 'finalize'
    task :finalize do
      recipe_path  = File.join(Dir.pwd, 'phases', 'finalize.rb')

      unless execution(['sudo', '-E', mitamae_path, 'local', '-y', profile_path, recipe_path].join(' '))
        abort('failed command')
      end
    end

    task :all => [:initialize, :provision, :finalize]
  end

  desc profile_name.gsub(/_/, ' ')
  task profile_name => ["#{profile_name}:all"]
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
