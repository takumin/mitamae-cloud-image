# frozen_string_literal: true

#
# Package Install
#

case node[:platform]
when 'debian', 'ubuntu'
  package 'openssh-server' do
    if node[:target][:role].match(/minimal/)
      options '--no-install-recommends'
    end
  end
when 'arch'
  package 'openssh'
else
  raise
end

#
# Remove Host Keys
#

%w{
  /etc/ssh/ssh_host_dsa_key
  /etc/ssh/ssh_host_dsa_key.pub
  /etc/ssh/ssh_host_ecdsa_key
  /etc/ssh/ssh_host_ecdsa_key.pub
  /etc/ssh/ssh_host_ed25519_key
  /etc/ssh/ssh_host_ed25519_key.pub
  /etc/ssh/ssh_host_rsa_key
  /etc/ssh/ssh_host_rsa_key.pub
}.each do |key|
  file key do
    action :delete
  end
end

#
# Check Role
#

unless node[:target][:role].match(/minimal/)
  return
end

#
# Generate Host Keys Service
#

contents = <<__EOF__
[Unit]
Description=Generate SSH Host Keys During Boot
Before=ssh.service
After=local-fs.target
ConditionPathExists=|!/etc/ssh/ssh_host_rsa_key
ConditionPathExists=|!/etc/ssh/ssh_host_rsa_key.pub

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/ssh-keygen -A

[Install]
WantedBy=multi-user.target
__EOF__

file '/etc/systemd/system/ssh-host-keygen.service' do
  owner   'root'
  group   'root'
  mode    '0644'
  content contents
end

service 'ssh-host-keygen.service' do
  action :enable
end

service 'ssh.service' do
  action :enable
end
