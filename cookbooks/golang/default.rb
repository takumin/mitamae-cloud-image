version = '1.18.2'

sha256sum = Hashie::Mash.new
sha256sum['amd64'] = 'e54bec97a1a5d230fc2f9ad0880fcbabb5888f30ed9666eca4a91c5a32e86cbc'
sha256sum['arm64'] = 'fc4ad28d0501eaa9c9d6190de3888c9d44d8b5fb02183ce4ae93713f67b8a35b'

case node[:kernel][:machine]
when 'x86_64'
  arch = 'amd64'
when 'aarch64'
  arch = 'arm64'
else
  raise
end

download_archive_url  = "https://dl.google.com/go/go#{version}.linux-#{arch}.tar.gz"
download_archive_name = File.basename(download_archive_url)
download_archive_path = File.join('/tmp', download_archive_name)

if File.exist?('/usr/local/go/bin/go') then
  check_version = run_command('/usr/local/go/bin/go version', error: false)

  if check_version.success? then
    installed_version = check_version.stdout.lines[0].gsub(/^go version go([0-9]+\.[0-9]+(?:\.[0-9]+)?).*$/, '\1').chomp

    if installed_version != version then
      directory '/usr/local/go' do
        action :delete
      end
    end
  end
end

http_request download_archive_path do
  url download_archive_url
  not_if [
    'test -d /usr/local/go',
    "echo #{sha256sum[arch]} #{download_archive_path} | sha256sum -c --ignore-missing --status",
  ].join(' || ')
end

execute "tar -xvf #{download_archive_path}" do
  cwd '/usr/local'
  not_if 'test -d /usr/local/go'
end

file download_archive_path do
  action :delete
  only_if 'test -d /usr/local/go'
end

remote_file '/etc/profile.d/go-path.sh' do
  owner 'root'
  group 'root'
  mode  '0644'
end

unless ENV['PATH'].include?('/usr/local/go/bin') then
  ENV['PATH'] << ':/usr/local/go/bin'
end
