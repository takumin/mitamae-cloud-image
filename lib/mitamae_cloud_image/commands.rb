# frozen_string_literal: true

module MitamaeCloudImage
  # The shell commands each phase runs, built without running them.
  # A step whose chroot is set runs processes inside that directory, which
  # must be killed on interrupt.
  class Commands
    Step = Struct.new(:command, :chroot)

    # sudo-rs (the default sudo since Ubuntu 25.10) ignores 'sudo -E', so pass
    # the variables the recipes read to the root processes by name instead
    PRESERVE_ENV_PATTERN = /\A(?:
      (?:ADMIN|APT_REPO|ARCH|DISABLE|ENABLE|WIFI_AP)_.+ |
      INITRAMFS_COMPRESS | OUTPUT_DIRECTORY | ROOTFS_ARCHIVE_FORMAT |
      TARGET_DIRECTORY | TIMEZONE | QEMU_CPU |
      (?i:(?:http|https|ftp|no)_proxy)
    )\z/x

    def self.sudo_preserve_env(env = ENV)
      names = env.keys.grep(PRESERVE_ENV_PATTERN).sort
      names.empty? ? [] : ["--preserve-env=#{names.join(',')}"]
    end

    attr_reader :root, :chroot_dir, :log_level, :preserve_env

    def initialize(root:, chroot_dir:, log_level:, preserve_env:)
      @root = File.expand_path(root)
      @chroot_dir = chroot_dir
      @log_level = log_level
      @preserve_env = preserve_env
    end

    def initialize_phase
      [
        Step.new(local_mitamae('./phases/initialize.rb'), chroot_dir),
      ]
    end

    def provision_phase
      rsync = [
        'sudo', 'rsync', '-a',
        '--exclude=".git/"',
        '--exclude="releases/"',
        "#{root}/",
        "#{File.join(chroot_dir, 'mitamae')}/"
      ].join(' ')

      mitamae = [
        'sudo', *preserve_env, 'chroot', chroot_dir,
        'mitamae', 'local',
        '-l', log_level,
        '-y', '/mitamae/.bin/profile.yaml',
        '--plugins=/mitamae/plugins',
        '/mitamae/phases/provision.rb',
      ].join(' ')

      [
        Step.new(rsync, nil),
        Step.new(mitamae, chroot_dir),
        Step.new("sudo rm -fr #{File.join(chroot_dir, 'mitamae')}", nil),
      ]
    end

    def finalize_phase
      releases = File.join(root, 'releases')

      [
        Step.new(local_mitamae('./phases/finalize.rb'), chroot_dir),
        Step.new("find #{releases} -type d | xargs sudo chmod 0755", nil),
        Step.new("find #{releases} -type f | xargs sudo chmod 0644", nil),
        Step.new("sudo chown -R $(id -u):$(id -g) #{releases}", nil),
      ]
    end

    private

    def local_mitamae(recipe)
      [
        'sudo', *preserve_env,
        './.bin/mitamae', 'local',
        '-l', log_level,
        '-y', './.bin/profile.yaml',
        recipe,
      ].join(' ')
    end
  end
end
