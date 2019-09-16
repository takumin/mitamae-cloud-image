#
# Validate Variables
#

node.validate! do
  {
    target: {
      distribution: match(/^(?:debian|ubuntu)$/),
      suite:        string,
      profile:      match(/^(?:minimal|server|desktop)$/),
      architecture: match(/^(?:i386|amd64|armhf|arm64)$/),
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
        suite:      match(/^(?:xenial|bionic)$/),
        components: array_of(match(/^(?:main|restricted|universe|multiverse)$/)),
      },
    }
  end
when :debian
  node.validate! do
    {
      target: {
        suite:      match(/^(?:jessie|stretch|buster)$/),
        components: array_of(match(/^(?:main|contrib|non-free)$/)),
      },
    }
  end
end