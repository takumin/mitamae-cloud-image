ENV['PATH']   = ENV['PATH'].split(':').unshift('/usr/local/go/bin').join(':')
ENV['GOPATH'] = '/tmp/desync'
ENV['GOBIN']  = '/usr/local/bin'
ENV['CGO_ENABLED'] = '0'

execute "go install -ldflags '-s -w' github.com/folbricht/desync/cmd/desync@latest" do
  not_if 'test -x /usr/local/bin/desync'
end

directory ENV['GOPATH'] do
  action :delete
end
