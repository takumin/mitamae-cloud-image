# frozen_string_literal: true

require_relative 'test_helper'

class TargetsTest < Minitest::Test
  Targets = MitamaeCloudImage::Targets

  def target(distribution, suite, kernel, architecture, role)
    Targets.build(
      'distribution' => distribution,
      'suite'        => suite,
      'kernel'       => kernel,
      'architecture' => architecture,
      'role'         => role,
    )
  end

  def names(targets)
    targets.map { |t| Targets.name(t) }
  end

  def test_build_orders_the_values_for_the_task_name
    t = Targets.build(
      'role'         => 'server',
      'architecture' => 'amd64',
      'kernel'       => 'generic',
      'suite'        => 'trixie',
      'distribution' => 'debian',
    )

    assert_equal 'debian:trixie:generic:amd64:server', Targets.name(t)
    assert_equal 'debian/trixie/generic/amd64/server', Targets.release_dir(t)
  end

  def test_build_requires_every_key
    assert_raises(KeyError) { Targets.build('distribution' => 'debian') }
  end

  def test_names_are_unique
    all = names(Targets.all({}))

    assert_equal all.uniq, all
  end

  def test_raspberrypi_is_arm64_only
    assert(Targets.all({}).select { |t| t['kernel'] == 'raspberrypi' }.all? { |t| t['architecture'] == 'arm64' })
  end

  def test_nvidia_roles_are_amd64_with_a_generic_or_proxmox_kernel
    nvidia = Targets.all({}).select { |t| t['role'].include?('nvidia') }

    refute_empty nvidia
    nvidia.each do |t|
      assert_equal 'amd64', t['architecture'], Targets.name(t)
      assert_match(/generic|proxmox/, t['kernel'], Targets.name(t))
    end
  end

  def test_supported
    assert Targets.supported?('generic', 'server', 'amd64')
    assert Targets.supported?('raspberrypi', 'server', 'arm64')
    assert Targets.supported?('generic-hwe', 'desktop-nvidia-cuda', 'amd64')
    refute Targets.supported?('raspberrypi', 'server', 'amd64')
    refute Targets.supported?('generic', 'server-nvidia-cuda', 'arm64')
    refute Targets.supported?('cloud', 'server-nvidia-cuda', 'amd64')
  end

  def test_extras
    assert_equal [
      'debian:bookworm:proxmox:amd64:proxmox-ve',
      'debian:trixie:proxmox:amd64:proxmox-ve',
      'debian:trixie:raspberrypi:arm64:kodi',
      'debian:trixie:raspberrypi:arm64:kodi-car',
    ], names(Targets.extras)
  end

  def test_nvidia_vgpu_is_enabled_unless_a_variable_is_empty
    assert Targets.nvidia_vgpu_enabled?({})
    assert Targets.nvidia_vgpu_enabled?('APT_REPO_PPA_NVIDIA_VGPU_URL' => 'http://example.com')
    refute Targets.nvidia_vgpu_enabled?('APT_REPO_PPA_NVIDIA_VGPU_URL' => '')
    refute Targets.nvidia_vgpu_enabled?(
      'APT_REPO_PPA_NVIDIA_VGPU_URL'         => 'http://example.com',
      'APT_REPO_PPA_NVIDIA_VGPU_KEYRING_URL' => '',
    )
  end

  def test_all_includes_nvidia_vgpu_only_when_enabled
    vgpu = names(Targets.nvidia_vgpu)

    assert_equal [
      'debian:trixie:generic-backports:amd64:server-nvidia-vgpu',
      'ubuntu:resolute:generic-hwe:amd64:server-nvidia-vgpu',
      'debian:bookworm:proxmox:amd64:proxmox-ve-nvidia-vgpu',
      'debian:trixie:proxmox:amd64:proxmox-ve-nvidia-vgpu',
    ], vgpu
    assert_empty vgpu - names(Targets.all({}))
    assert_empty vgpu & names(Targets.all('APT_REPO_PPA_NVIDIA_VGPU_URL' => ''))
  end

  def test_chroot_dir
    t = target('debian', 'trixie', 'generic', 'amd64', 'server')

    assert_equal '/tmp/debian-trixie-generic-amd64-server', Targets.chroot_dir(t, {})
    assert_equal '/mnt/rootfs', Targets.chroot_dir(t, 'TARGET_DIRECTORY' => '/mnt/rootfs')
  end

  def test_publish
    assert Targets.publish?(target('ubuntu', 'resolute', 'generic-hwe', 'amd64', 'server'))
    assert Targets.publish?(target('ubuntu', 'resolute', 'virtual-hwe', 'amd64', 'server'))
    assert Targets.publish?(target('ubuntu', 'resolute', 'raspberrypi', 'arm64', 'server'))
    assert Targets.publish?(target('debian', 'trixie', 'cloud-backports', 'amd64', 'server'))
    assert Targets.publish?(target('debian', 'trixie', 'proxmox', 'amd64', 'proxmox-ve'))
    refute Targets.publish?(target('ubuntu', 'resolute', 'generic', 'amd64', 'server'))
    refute Targets.publish?(target('ubuntu', 'noble', 'generic-hwe', 'amd64', 'server'))
    refute Targets.publish?(target('debian', 'bookworm', 'generic-backports', 'amd64', 'server'))
    refute Targets.publish?(target('debian', 'trixie', 'generic-backports-rt', 'amd64', 'server'))
    refute Targets.publish?(target('arch', 'rolling', 'generic', 'amd64', 'server'))
  end

  def test_github_actions_matrix
    targets = [
      target('ubuntu', 'resolute', 'generic-hwe', 'amd64', 'server'),
      target('ubuntu', 'resolute', 'raspberrypi', 'arm64', 'desktop'),
      target('ubuntu', 'resolute', 'generic-hwe', 'amd64', 'desktop-nvidia-legacy'),
      target('ubuntu', 'resolute', 'generic-hwe', 'amd64', 'desktop-rtl8852au-nvidia-cuda'),
      target('ubuntu', 'resolute', 'generic-hwe', 'amd64', 'minimal-bootstrap'),
      target('ubuntu', 'noble', 'generic-hwe', 'amd64', 'server'),
    ]

    assert_equal [
      {
        name:   'ubuntu:resolute:generic-hwe:amd64:server',
        dir:    'ubuntu/resolute/generic-hwe/amd64/server',
        runner: 'ubuntu-26.04',
      },
      {
        name:   'ubuntu:resolute:raspberrypi:arm64:desktop',
        dir:    'ubuntu/resolute/raspberrypi/arm64/desktop',
        runner: 'ubuntu-26.04-arm',
      },
    ], Targets.github_actions_matrix(targets)
  end

  def test_github_actions_matrix_does_not_modify_the_targets
    targets = Targets.all({})

    refute_empty Targets.github_actions_matrix(targets)
    assert_equal Targets.all({}), targets
  end
end
