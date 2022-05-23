http_request '/usr/local/bin/zsyncmake2' do
  url    'https://github.com/AppImage/zsync2/releases/download/2.0.0-alpha-1-20220517/zsyncmake2-47-1f5749c-x86_64.AppImage'
  owner  'root'
  group  'root'
  mode   '0755'
  not_if 'test -x /usr/local/bin/zsyncmake2'
end
