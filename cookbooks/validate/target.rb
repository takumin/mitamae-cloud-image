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
]

node.validate! do
  {
    target: {
      distribution: match(/^(?:debian|ubuntu|arch)$/),
      architecture: match(/^(?:i386|amd64|armhf|arm64)$/),
      roles:        array_of(match(/^(?:#{AVAILABLE_ROLES.join('|')})$/)),
      directory:    string,
    },
  }
end

case node[:target][:distribution]
when :ubuntu
  node.validate! do
    {
      target: {
        kernel:     match(/^(?:generic|generic-hwe|virtual|virtual-hwe)$/),
        suite:      match(/^(?:xenial|bionic|focal)$/),
        components: array_of(match(/^(?:main|restricted|universe|multiverse)$/)),
      },
    }
  end
when :debian
  node.validate! do
    {
      target: {
        kernel:     match(/^(?:generic|cloud)$/),
        suite:      match(/^(?:jessie|stretch|buster|bullseye)$/),
        components: array_of(match(/^(?:main|contrib|non-free)$/)),
      },
    }
  end
end
