#
# Validate Variables
#

node.validate! do
  {
    target: {
      distribution: match(/^(?:debian|ubuntu)$/),
      suite:        string,
      architecture: match(/^(?:i386|amd64|armhf|arm64)$/),
      role:         match(/^(?:minimal|server|desktop|server-nvidia|desktop-nvidia)$/),
      components:   array_of(string),
      directory:    string,
    },
  }
end

case node[:debootstrap][:target]
when :ubuntu
  node.validate! do
    {
      target: {
        kernel:     match(/^(?:generic|generic-hwe|virtual|virtual-hwe)$/),
        suite:      match(/^(?:xenial|bionic)$/),
        components: array_of(match(/^(?:main|restricted|universe|multiverse)$/)),
      },
    }
  end
when :debian
  node.validate! do
    {
      target: {
        kernel:     match(/^(?:generic|cloud)$/),
        suite:      match(/^(?:jessie|stretch|buster)$/),
        components: array_of(match(/^(?:main|contrib|non-free)$/)),
      },
    }
  end
end
