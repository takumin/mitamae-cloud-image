# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match?(/bootstrap/)
  return
end

#
# Required Packages
#

package 'dnsmasq'

#
# Systemd Service
#

dnsmasq_bin = '/usr/sbin/dnsmasq'
dnsmasq_conf = '/etc/dnsmasq.conf'
dnsmasq_conf_d = '/etc/dnsmasq.d'
dnsmasq_run_d = '/run/dnsmasq'

dnsmasq_owner = 'dnsmasq'
dnsmasq_group = 'nogroup'

contents = <<__EOF__
[Unit]
Description=Dnsmasq - A lightweight DHCP and caching DNS server
Documentation=https://thekelleys.org.uk/dnsmasq/doc.html
Wants=nss-lookup.target
Before=nss-lookup.target
Requires=network.target
After=network.target
ConditionFileIsExecutable=#{dnsmasq_bin}
ConditionPathIsDirectory=#{dnsmasq_conf_d}
ConditionFileNotEmpty=#{dnsmasq_conf}

[Service]
# Resource Control
DevicePolicy=closed
IPAddressAllow=any
SocketBindAllow=any

# Sandboxing
LockPersonality=true
MemoryDenyWriteExecute=true
MountAPIVFS=true
MountFlags=private
ProcSubset=pid
RemoveIPC=true

# Sandboxing - Private
PrivateDevices=true
PrivateTmp=true
# bind permission error
#PrivateUsers=true

# Sandboxing - Protect
ProtectSystem=strict
ProtectClock=true
ProtectControlGroups=true
ProtectHome=true
ProtectHostname=true
ProtectKernelLogs=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectProc=invisible

# Sandboxing - Restrict
RestrictAddressFamilies=AF_NETLINK AF_PACKET AF_UNIX AF_INET AF_INET6
RestrictNamespaces=true
RestrictRealtime=true
RestrictSUIDSGID=true

# Sandboxing - Path
# dnsmasq --test error
#ReadOnlyPaths=/
#InaccessiblePaths=-/lost+found
#NoExecPaths=/
#ExecPaths=#{dnsmasq_bin}

# System Call Filtering
SystemCallArchitectures=native
SystemCallFilter=@system-service
SystemCallFilter=~@privileged
SystemCallFilter=~@resources

# Capabilities
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

# Security
NoNewPrivileges=true
SecureBits=keep-caps

# Permission
UMask=0027

# Tuning
LimitNOFILE=#{1024 * 512}
LimitNPROC=1024

# User/Group
User=#{dnsmasq_owner}
Group=#{dnsmasq_group}

# Directory
RuntimeDirectory=dnsmasq
ConfigurationDirectory=dnsmasq.d

# Service Type
Type=forking

# Process ID
PIDFile=#{dnsmasq_run_d}/dnsmasq.pid

# Service
ExecStartPre=#{dnsmasq_bin} \\
          --test \\
          --pid-file=#{dnsmasq_run_d}/dnsmasq.pid \\
          --conf-dir=#{dnsmasq_conf_d},.dpkg-dist,.dpkg-old,.dpkg-new \\
          --local-service
ExecStart=#{dnsmasq_bin} \\
          --pid-file=#{dnsmasq_run_d}/dnsmasq.pid \\
          --conf-dir=#{dnsmasq_conf_d},.dpkg-dist,.dpkg-old,.dpkg-new \\
          --local-service

# Restart
Restart=on-failure

[Install]
WantedBy=multi-user.target
__EOF__

file '/etc/systemd/system/dnsmasq.service' do
  owner  'root'
  group  'root'
  mode   '0644'
  content contents
  notifies :run, 'execute[systemctl daemon-reload]'
end

#
# Service Configuration
#

file '/etc/dnsmasq.d/systemd-resolved' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<~__EOF__
  listen-address=127.0.0.1
  listen-address=::1
  except-interface=lo
  bind-dynamic
  __EOF__
end

#
# Reload Systemd
#

execute 'systemctl daemon-reload' do
  action :nothing
end
