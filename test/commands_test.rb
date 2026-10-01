# frozen_string_literal: true

require_relative 'test_helper'

class CommandsTest < Minitest::Test
  Commands = MitamaeCloudImage::Commands

  def commands(preserve_env: [])
    Commands.new(
      root:         '/src/mitamae-cloud-image',
      chroot_dir:   '/mnt/rootfs',
      log_level:    'debug',
      preserve_env: preserve_env,
    )
  end

  def test_sudo_preserve_env_selects_the_variables_the_recipes_read
    env = {
      'TIMEZONE'                => 'UTC',
      'APT_REPO_URL_DEBIAN'     => 'http://example.com/debian',
      'DISABLE_SQUASHFS'        => 'true',
      'https_proxy'             => 'http://proxy',
      'HTTP_PROXY'              => 'http://proxy',
      'HOME'                    => '/root',
      'PATH'                    => '/usr/bin',
      'TIMEZONE_EXTRA'          => 'x',
      'APT_REPO'                => 'x',
    }

    assert_equal [
      '--preserve-env=APT_REPO_URL_DEBIAN,DISABLE_SQUASHFS,HTTP_PROXY,TIMEZONE,https_proxy',
    ], Commands.sudo_preserve_env(env)
  end

  def test_sudo_preserve_env_is_empty_without_matching_variables
    assert_equal [], Commands.sudo_preserve_env('HOME' => '/root')
  end

  def test_initialize_phase
    steps = commands(preserve_env: ['--preserve-env=TIMEZONE']).initialize_phase

    assert_equal [
      Commands::Step.new(
        'sudo --preserve-env=TIMEZONE ./.bin/mitamae local -l debug -y ./.bin/profile.yaml ./phases/initialize.rb',
        '/mnt/rootfs',
      ),
    ], steps
  end

  def test_provision_phase
    steps = commands.provision_phase

    assert_equal [
      Commands::Step.new(
        'sudo rsync -a --exclude=".git/" --exclude="releases/" /src/mitamae-cloud-image/ /mnt/rootfs/mitamae/',
        nil,
      ),
      Commands::Step.new(
        'sudo chroot /mnt/rootfs mitamae local -l debug -y /mitamae/.bin/profile.yaml ' \
        '--plugins=/mitamae/plugins /mitamae/phases/provision.rb',
        '/mnt/rootfs',
      ),
      Commands::Step.new('sudo rm -fr /mnt/rootfs/mitamae', nil),
    ], steps
  end

  def test_finalize_phase
    steps = commands.finalize_phase

    assert_equal [
      Commands::Step.new(
        'sudo ./.bin/mitamae local -l debug -y ./.bin/profile.yaml ./phases/finalize.rb',
        '/mnt/rootfs',
      ),
      Commands::Step.new('find /src/mitamae-cloud-image/releases -type d | xargs sudo chmod 0755', nil),
      Commands::Step.new('find /src/mitamae-cloud-image/releases -type f | xargs sudo chmod 0644', nil),
      Commands::Step.new('sudo chown -R $(id -u):$(id -g) /src/mitamae-cloud-image/releases', nil),
    ], steps
  end

  def test_root_is_expanded
    c = Commands.new(root: '/src/x/../mitamae-cloud-image', chroot_dir: '/mnt/rootfs', log_level: 'info', preserve_env: [])

    assert_equal '/src/mitamae-cloud-image', c.root
  end
end
