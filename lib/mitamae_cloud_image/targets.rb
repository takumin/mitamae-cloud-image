# frozen_string_literal: true

module MitamaeCloudImage
  # The build targets. A target is a Hash whose values, in insertion order,
  # form its task name, release directory and default chroot directory.
  module Targets
    PUBLISH_UBUNTU_SUITE = 'resolute'
    PUBLISH_DEBIAN_SUITE = 'trixie'

    DISTRIBUTIONS = [
      'debian',
      'ubuntu',
    ].freeze

    SUITES = {
      'debian' => [
        'bookworm',
        'trixie',
      ],
      'ubuntu' => [
        'noble',
        'resolute',
      ],
    }.freeze

    KERNELS = {
      'debian' => [
        'generic',
        'generic-backports',
        'cloud',
        'cloud-backports',
        'raspberrypi',
      ],
      'ubuntu' => [
        'generic',
        'generic-hwe',
        'virtual',
        'virtual-hwe',
        'raspberrypi',
      ],
    }.freeze

    ROLES = {
      'debian' => [
        'minimal',
        'minimal-bootstrap',
        'server',
        'server-nvidia-cuda',
        'server-nvidia-legacy',
        'desktop',
        'desktop-nvidia-cuda',
        'desktop-nvidia-legacy',
        'desktop-rtl8852au-nvidia-cuda',
      ],
      'ubuntu' => [
        'minimal',
        'minimal-bootstrap',
        'server',
        'server-nvidia-cuda',
        'server-nvidia-legacy',
        'desktop',
        'desktop-nvidia-cuda',
        'desktop-nvidia-legacy',
        'desktop-rtl8852au-nvidia-cuda',
      ],
    }.freeze

    ARCHITECTURES = [
      'amd64',
      'arm64',
    ].freeze

    NVIDIA_VGPU_ENV_KEYS = %w{
      APT_REPO_PPA_NVIDIA_VGPU_KEYRING_UID
      APT_REPO_PPA_NVIDIA_VGPU_KEYRING_FINGER_PRINT
      APT_REPO_PPA_NVIDIA_VGPU_KEYRING_URL
      APT_REPO_PPA_NVIDIA_VGPU_URL
    }.freeze

    # NOTE: Unused NVIDIA Legacy Version, rtl8852au and bootstrap
    UNUSED_ROLE_PATTERNS = [
      'nvidia-legacy',
      'rtl8852au',
      'bootstrap',
    ].freeze

    module_function

    def build(target)
      {
        'distribution' => target.fetch('distribution'),
        'suite'        => target.fetch('suite'),
        'kernel'       => target.fetch('kernel'),
        'architecture' => target.fetch('architecture'),
        'role'         => target.fetch('role'),
      }
    end

    def all(env = ENV)
      targets = matrix
      targets.concat(extras)
      targets.concat(nvidia_vgpu) if nvidia_vgpu_enabled?(env)
      targets
    end

    def matrix
      DISTRIBUTIONS.flat_map do |distribution|
        SUITES[distribution].product(KERNELS[distribution], ROLES[distribution], ARCHITECTURES)
          .select { |_, kernel, role, architecture| supported?(kernel, role, architecture) }
          .map do |suite, kernel, role, architecture|
            build(
              'distribution' => distribution,
              'suite'        => suite,
              'kernel'       => kernel,
              'architecture' => architecture,
              'role'         => role,
            )
          end
      end
    end

    def supported?(kernel, role, architecture)
      return false if architecture == 'amd64' and kernel == 'raspberrypi'
      return false if architecture != 'amd64' and role.include?('nvidia')
      return false if !kernel.include?('generic') and role.include?('nvidia')

      true
    end

    def extras
      proxmox = SUITES['debian'].map do |suite|
        build(
          'distribution' => 'debian',
          'suite'        => suite,
          'kernel'       => 'proxmox',
          'architecture' => 'amd64',
          'role'         => 'proxmox-ve',
        )
      end

      kodi = %w{kodi kodi-car}.map do |role|
        build(
          'distribution' => 'debian',
          'suite'        => PUBLISH_DEBIAN_SUITE,
          'kernel'       => 'raspberrypi',
          'architecture' => 'arm64',
          'role'         => role,
        )
      end

      proxmox + kodi
    end

    # The vGPU targets are built unless one of the repository variables is
    # set but empty, as GitHub Actions does for a secret that is not defined
    def nvidia_vgpu_enabled?(env = ENV)
      NVIDIA_VGPU_ENV_KEYS.none? { |key| env.key?(key) and env[key].empty? }
    end

    def nvidia_vgpu
      server = [
        ['debian', 'trixie', 'generic-backports'],
        ['ubuntu', 'resolute', 'generic-hwe'],
      ].map do |distribution, suite, kernel|
        build(
          'distribution' => distribution,
          'suite'        => suite,
          'kernel'       => kernel,
          'architecture' => 'amd64',
          'role'         => 'server-nvidia-vgpu',
        )
      end

      proxmox = SUITES['debian'].map do |suite|
        build(
          'distribution' => 'debian',
          'suite'        => suite,
          'kernel'       => 'proxmox',
          'architecture' => 'amd64',
          'role'         => 'proxmox-ve-nvidia-vgpu',
        )
      end

      server + proxmox
    end

    def name(target)
      target.values.join(':')
    end

    def release_dir(target)
      target.values.join('/')
    end

    def chroot_dir(target, env = ENV)
      env['TARGET_DIRECTORY'] || "/tmp/#{target.values.join('-')}"
    end

    def publish?(target)
      case target['distribution']
      when 'ubuntu'
        target['suite'].eql?(PUBLISH_UBUNTU_SUITE) and
          target['kernel'].match?(/^((generic|virtual)-hwe|raspberrypi)$/)
      when 'debian'
        target['suite'].eql?(PUBLISH_DEBIAN_SUITE) and
          target['kernel'].match?(/^((generic|cloud)-backports|raspberrypi|proxmox)$/)
      else
        false
      end
    end

    def used?(target)
      UNUSED_ROLE_PATTERNS.none? { |pattern| target['role'].include?(pattern) }
    end

    def runner(target)
      target['architecture'].eql?('arm64') ? 'ubuntu-26.04-arm' : 'ubuntu-26.04'
    end

    # Unpublished targets are kept for local builds only
    def github_actions_matrix(targets)
      targets.select { |target| used?(target) and publish?(target) }.map do |target|
        {
          name:   name(target),
          dir:    release_dir(target),
          runner: runner(target),
        }
      end
    end
  end
end
