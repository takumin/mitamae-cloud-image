http_request '/usr/local/bin/extract-vmlinux' do
  url    'https://raw.githubusercontent.com/torvalds/linux/master/scripts/extract-vmlinux'
  owner  'root'
  group  'root'
  mode   '0755'
  not_if 'test -x /usr/local/bin/extract-vmlinux'
end
