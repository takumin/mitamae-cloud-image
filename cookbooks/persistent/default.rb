# frozen_string_literal: true

file '/etc/systemd/system/srv.mount' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<~__EOF__
    [Unit]
    Description=Site-specific Pertition

    [Mount]
    What=/dev/disk/by-partlabel/SRVDATA
    Where=/srv
    Type=xfs
    Options=defaults,nofail

    [Install]
    WantedBy=multi-user.target
  __EOF__
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

file '/etc/systemd/system/srv.automount' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<~__EOF__
    [Unit]
    Description=Automount Site-specific Pertition

    [Automount]
    Where=/srv
    TimeoutIdleSec=300

    [Install]
    WantedBy=multi-user.target
  __EOF__
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

execute 'systemctl daemon-reload' do
  action :nothing
end

service 'srv.mount' do
  action :disable
end

service 'srv.automount' do
  action :enable
end
