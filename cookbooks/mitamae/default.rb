# frozen_string_literal: true

#
# Public Variables
#

node[:mitamae] ||= Hashie::Mash.new

#
# Public Variables - Version
#

node[:mitamae][:version] ||= '1.12.9'

#
# Public Variables - Architecture
#

case node[:target][:architecture]
when 'i386'
  node[:mitamae][:architecture] = 'i686'
when 'amd64'
  node[:mitamae][:architecture] = 'x86_64'
when 'armhf'
  node[:mitamae][:architecture] = 'armhf'
when 'arm64'
  node[:mitamae][:architecture] = 'aarch64'
end

#
# Public Variables - Target Directory
#

node[:mitamae][:target_dir] ||= ENV['TARGET_DIRECTORY'] || node[:target][:directory]

#
# Public Variables - Download Binary URL
#

node[:mitamae][:binary_url] ||= File.join(
  "https://github.com/itamae-kitchen/mitamae/releases/download/",
  "v#{node[:mitamae][:version]}",
  "mitamae-#{node[:mitamae][:architecture]}-linux",
)

#
# Validate Variables
#

node.validate! do
  {
    mitamae: {
      version:      match(/^[0-9]+\.[0-9]+\.[0-9]+$/),
      architecture: match(/^(?:i686|x86_64|armhf|aarch64)$/),
      target_dir:   string,
    },
  }
end

#
# Install Binary
#

http_request '/usr/local/bin/mitamae' do
  path   'usr/local/bin/mitamae'
  cwd    node[:mitamae][:target_dir]
  url    node[:mitamae][:binary_url]
  owner  'root'
  group  'root'
  mode   '0755'
  not_if 'test -x usr/local/bin/mitamae'
  # disable debug log
  sensitive true
end
