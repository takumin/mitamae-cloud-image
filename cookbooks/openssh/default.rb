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
# Cipher Preference
#

# The client's order picks the cipher, so sshd can only prefer ChaCha20-Poly1305 by dropping AES-GCM.
# Raspberry Pi 4 and older lack the ARMv8 AES instructions, and the image is shared with the Raspberry Pi 5,
# which has them, so the drop-in is written on boot from /proc/cpuinfo. AES-CTR stays for clients without
# ChaCha20-Poly1305, such as Paramiko, libssh2 and FIPS mode.
if node[:target][:kernel].eql?('raspberrypi')
  contents = <<~__EOF__
    #!/bin/sh

    set -eu

    CONF='/etc/ssh/sshd_config.d/10-cipher-preference.conf'

    if grep -qw aes /proc/cpuinfo; then
      rm -f "${CONF}"
    else
      echo 'Ciphers -aes*-gcm@openssh.com' > "${CONF}.tmp"
      mv -f "${CONF}.tmp" "${CONF}"
    fi
  __EOF__

  directory '/usr/local/libexec' do
    owner 'root'
    group 'root'
    mode  '0755'
  end

  file '/usr/local/libexec/ssh-cipher-preference' do
    owner   'root'
    group   'root'
    mode    '0755'
    content contents
  end

  contents = <<~__EOF__
    [Unit]
    Description=Prefer ChaCha20-Poly1305 for SSH Without AES Instructions
    Before=ssh.service ssh.socket
    After=local-fs.target

    [Service]
    Type=oneshot
    RemainAfterExit=yes
    ExecStart=/usr/local/libexec/ssh-cipher-preference

    [Install]
    WantedBy=multi-user.target
  __EOF__

  file '/etc/systemd/system/ssh-cipher-preference.service' do
    owner   'root'
    group   'root'
    mode    '0644'
    content contents
  end

  service 'ssh-cipher-preference.service' do
    action :enable
  end
end

#
# Check Role
#

# Roles without cloud-init need their own host key generation; the packaged sshd-keygen.service is
# ConditionFirstBoot=yes, which never holds because the cleanup cookbook leaves /etc/machine-id empty
unless node[:target][:role].match?(/(?:minimal|proxmox-ve)/)
  return
end

#
# Generate Host Keys Service
#

contents = <<~__EOF__
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
