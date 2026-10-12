# frozen_string_literal: true

#
# Check Distribution
#

# seednet goes into the dracut initrd, which only Debian and Ubuntu have here.
unless node[:target][:distribution].match(/^(debian|ubuntu)$/)
  return
end

#
# Public Variables
#

node[:seednet] ||= Hashie::Mash.new

#
# Public Variables - Version
#

node[:seednet][:version] ||= '0.2.0'

#
# Public Variables - Architecture
#

case node[:target][:architecture]
when 'amd64'
  node[:seednet][:architecture] = 'x86_64'
when 'arm64'
  node[:seednet][:architecture] = 'aarch64'
end

#
# Validate Variables
#

node.validate! do
  {
    seednet: {
      version:      match(/^[0-9]+\.[0-9]+\.[0-9]+$/),
      architecture: match(/^(?:x86_64|aarch64)$/),
    },
  }
end

#
# Private Variables
#

base_url     = "https://github.com/takumin/seednet/releases/download/v#{node[:seednet][:version]}"
binary       = "seednet-#{node[:seednet][:architecture]}-unknown-linux-musl"
contrib      = 'seednet-contrib.tar.gz'
download_dir = "/tmp/seednet-#{node[:seednet][:version]}"
contrib_dir  = "#{download_dir}/contrib"

# The previous build restored from its squashfs keeps the version it has.
installed = "test \"$(seednet --version 2>/dev/null)\" = 'seednet-cli #{node[:seednet][:version]}'"

#
# Download Release
#

directory download_dir do
  owner  'root'
  group  'root'
  mode   '0755'
  not_if installed
end

[binary, contrib, 'SHA256SUMS'].each do |name|
  http_request "#{download_dir}/#{name}" do
    url    "#{base_url}/#{name}"
    owner  'root'
    group  'root'
    mode   '0644'
    not_if installed
    # disable debug log
    sensitive true
  end
end

#
# Verify Release
#

# Only the files downloaded above, which are all the release has but the binaries of other architectures.
execute 'sha256sum -c --ignore-missing SHA256SUMS' do
  cwd    download_dir
  not_if installed
end

#
# Extract Contrib
#

execute "tar -xzf #{contrib}" do
  cwd    download_dir
  not_if installed
end

#
# Install Contrib
#

# The dracut module brings up the network of the initrd from the NoCloud seed at seednet.url.
execute "rm -rf /usr/lib/dracut/modules.d/95seednet && cp -r #{contrib_dir}/dracut/95seednet /usr/lib/dracut/modules.d/95seednet" do
  not_if installed
end

# seednet.service brings up the network of the root from the same seed.
execute "install -m 0755 #{contrib_dir}/systemd/seednet-rootfs /usr/libexec/seednet-rootfs" do
  not_if installed
end

execute "install -m 0644 #{contrib_dir}/systemd/seednet.service /usr/lib/systemd/system/seednet.service" do
  not_if installed
end

#
# Install Binary
#

# Last, as the version it reports is what tells the steps above they are done.
execute "install -m 0755 #{download_dir}/#{binary} /usr/bin/seednet" do
  not_if installed
end

#
# Cleanup
#

directory download_dir do
  action :delete
end

#
# Enable Service
#

service 'seednet.service' do
  action :enable
end
