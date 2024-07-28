#
# Validate Variables
#

AVAILABLE_ROLES = [
  'minimal',
  'server',
  'desktop',
  'server-nvidia',
  'desktop-nvidia',
  'server-nvidia-cuda',
  'desktop-nvidia-cuda',
  'desktop-rtl8852au-nvidia-cuda',
  'server-nvidia-legacy',
  'desktop-nvidia-legacy',
  'server-nvidia-vgpu',
  'proxmox-ve',
  'proxmox-ve-nvidia-vgpu',
]

node.validate! do
  {
    target: {
      distribution: match(/^(?:debian|ubuntu|arch)$/),
      architecture: match(/^(?:i386|amd64|armhf|arm64)$/),
      role:         match(/^(?:#{AVAILABLE_ROLES.join('|')})$/),
      directory:    string,
    },
  }
end

case node.target.distribution
when 'ubuntu'
  node.validate! do
    {
      target: {
        kernel:     match(/^(?:(?:generic|virtual|lowlatency)(?:-hwe)?|raspi)$/),
        suite:      match(/^(?:jammy|noble)$/),
        components: array_of(match(/^(?:main|restricted|universe|multiverse)$/)),
      },
    }
  end
when 'debian'
  node.validate! do
    {
      target: {
        kernel:     match(/^(?:generic|cloud|rt|raspberrypi|proxmox)(?:-backports)?$/),
        suite:      match(/^(?:bullseye|bookworm)$/),
        components: array_of(match(/^(?:main|contrib|non-free|non-free-firmware)$/)),
      },
    }
  end
when 'arch'
  node.validate! do
    {
      target: {
        kernel: match(/^(?:linux)(?:-lts)?$/),
      },
    }
  end
else
  raise
end
