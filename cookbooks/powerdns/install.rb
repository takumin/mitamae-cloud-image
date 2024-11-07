# frozen_string_literal: true

#
# Check Roles
#

unless node.target.role.match(/bootstrap/)
  return
end

#
# Apt Pinned
#

file '/etc/apt/preferences.d/powerdns' do
  owner 'root'
  group 'root'
  mode  '0644'
  content <<~__EOF__
    Package: *
    Pin: release o=PowerDNS
    Pin-Priority: 600
  __EOF__
end

#
# Apt Keyring
#

directory '/etc/apt/keyrings' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/etc/apt/keyrings/powerdns.asc' do
  owner  'root'
  group  'root'
  mode   '0644'
  source 'keyring.asc'
end

#
# Apt Repository
#

apt_repository 'PowerDNS Repository' do
  path '/etc/apt/sources.list.d/powerdns.list'
  entry [
    {
      :default_uri => "http://repo.powerdns.com/#{node.platform}",
      :mirror_uri  => ENV['APT_REPO_URL_POWERDNS_' + node.platform.upcase],
      :options     => 'signed-by=/etc/apt/keyrings/powerdns.asc',
      :suite       => '###platform_codename###-auth-49',
      :components  => ['main'],
    },
    {
      :default_uri => "http://repo.powerdns.com/#{node.platform}",
      :mirror_uri  => ENV['APT_REPO_URL_POWERDNS_' + node.platform.upcase],
      :options     => 'signed-by=/etc/apt/keyrings/powerdns.asc',
      :suite       => '###platform_codename###-rec-51',
      :components  => ['main'],
    },
    {
      :default_uri => "http://repo.powerdns.com/#{node.platform}",
      :mirror_uri  => ENV['APT_REPO_URL_POWERDNS_' + node.platform.upcase],
      :options     => 'signed-by=/etc/apt/keyrings/powerdns.asc',
      :suite       => '###platform_codename###-dnsdist-19',
      :components  => ['main'],
    },
  ]
  notifies :run, 'execute[apt-get update]', :immediately
end

#
# Event Handler
#

execute 'apt-get update' do
  action :nothing
end

#
# Required Packages
#

package 'dnsdist'
package 'pdns-server'
package 'pdns-recursor'

#
# Restore Configuration - PowerDNS
#

directory '/usr/local/libexec' do
  owner 'root'
  group 'root'
  mode  '0755'
end

file '/usr/local/libexec/powerdns-restore-config' do
  owner 'root'
  group 'root'
  mode  '0755'
  content <<~__EOF__
    #!/bin/sh
    /usr/bin/rsync -av --delete /srv/dnsdist/ /etc/dnsdist/
    /usr/bin/rsync -av --delete /srv/powerdns/ /etc/powerdns/
  __EOF__
end

file '/etc/systemd/system/powerdns-restore-config.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  content <<~__EOF__
    [Unit]
    Description=PowerDNS Restore Configuration
    Before=dnsdist.service
    Before=pdns.service
    Before=pdns-recursor.service
    Wants=srv.mount
    After=srv.mount
    ConditionPathIsMountPoint=/srv
    ConditionDirectoryNotEmpty=/srv/dnsdist
    ConditionDirectoryNotEmpty=/srv/powerdns
    ConditionPathIsDirectory=/etc/dnsdist
    ConditionPathIsDirectory=/etc/powerdns
    ConditionPathIsReadWrite=/etc/dnsdist
    ConditionPathIsReadWrite=/etc/powerdns

    [Service]
    Type=oneshot
    ExecStart=/usr/local/libexec/powerdns-restore-config

    [Install]
    WantedBy=multi-user.target
  __EOF__
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

execute 'systemctl daemon-reload' do
  action :nothing
end

service 'powerdns-restore-config.service' do
  action :enable
end

#
# Disable Systemd Resolved
#

service 'systemd-resolved.service' do
  action :disable
end

#
# Remove System Resolv
#

file '/etc/resolv.conf' do
  action :delete
  only_if 'test "symbolic link" = "$(LC_ALL=C stat -c "%F" /etc/resolv.conf)"'
end

#
# Configure System Resolv
#

file '/etc/resolv.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  content <<~__EOF__
    nameserver 127.0.0.1
    search .
    options timeout:1 inet6 edns0 trust-ad
  __EOF__
end

#
# Configure Authoritative
#

contents = ['launch=']

node.powerdns.config.authoritative.each do |key, val|
  case val
  when Hash
    val.each do |k, v|
      case v
      when Array
        contents << "#{k}=#{v.join(',')}"
      when Numeric, String
        contents << "#{k}=#{v.to_s}"
      when TrueClass
        contents << "#{k}=yes"
      when FalseClass
        contents << "#{k}=no"
      when Hash
        raise
      end
    end
  when Array
    contents << "#{key}=#{val.join(',')}"
  when Numeric, String
    contents << "#{key}=#{val.to_s}"
  else
    raise
  end
end

file '/etc/powerdns/pdns.conf' do
  owner 'root'
  group 'root'
  mode '0644'
  content contents.sort.join("\n").concat("\n")
end

#
# Configure Authoritative Backend
#

node.powerdns.backend.keys.each do |backend|
  contents = ["launch+=#{backend}"]

  node.powerdns.backend[backend].each do |key, val|
    case val
    when Hash
      val.each do |k, v|
        case v
        when Array
          contents << "#{backend}-#{k}=#{v.join(',')}"
        when Numeric, String
          contents << "#{backend}-#{k}=#{v.to_s}"
        when TrueClass
          contents << "#{backend}-#{k}=yes"
        when FalseClass
          contents << "#{backend}-#{k}=no"
        when Hash
          raise
        end
      end
    when Array
      contents << "#{backend}-#{key}=#{val.join(',')}"
    when Numeric, String
      contents << "#{backend}-#{key}=#{val.to_s}"
    else
      raise
    end
  end

  file "/etc/powerdns/pdns.d/#{backend}.conf" do
    owner 'root'
    group 'root'
    mode '0644'
    content contents.sort.join("\n").concat("\n")
  end
end

#
# Remove Recursor Old Config
#

file '/etc/powerdns/recursor.conf' do
  action :delete
end

#
# Configure Recursor
#

file '/etc/powerdns/recursor.yml' do
  owner 'root'
  group 'root'
  mode '0644'
  content YAML.dump(node.powerdns.config.recursor).gsub(/^(?:---|--- {}|\.\.\.)\n/, '')
end

#
# Configure Dnsdist
#

contents = [
  '-- vim: set ft=lua :',
]

contents << ''
contents << "newServer({address=\"#{node.powerdns.config.dnsdist.authoritative}\", pool=\"pool_authoritative\"})"
contents << "newServer({address=\"#{node.powerdns.config.dnsdist.recursor}\", pool=\"pool_recursor\"})"

contents << ''
contents << 'match_local_domain = newSuffixMatchNode()'
node.powerdns.config.dnsdist.local_domain.each do |domain|
  contents << "match_local_domain:add(newDNSName(\"#{domain}\"))"
end

contents << ''
contents << 'match_local_network = newNMG()'
node.powerdns.config.dnsdist.local_network.each do |network|
  contents << "match_local_network:addMask(\"#{network}\")"
end

contents << ''
contents << 'addAction(AndRule({'
contents << '  SuffixMatchNodeRule(match_local_domain),'
contents << '  NetmaskGroupRule(match_local_network)'
contents << '}), PoolAction("pool_authoritative"))'

contents << ''
contents << 'addAction(AndRule({'
contents << '  NotRule(SuffixMatchNodeRule(match_local_domain)),'
contents << '  NetmaskGroupRule(match_local_network)'
contents << '}), PoolAction("pool_recursor"))'

contents << ''
contents << 'addAction(AllRule(), RCodeAction(DNSRCode.REFUSED))'

# TODO
contents << ''
for i in 0..3 do
  contents << 'addLocal("0.0.0.0:53", { reusePort=true })'
  contents << 'addLocal("[::]:53", { reusePort=true })'
end

file '/etc/dnsdist/dnsdist.conf' do
  owner 'root'
  group 'root'
  mode '0644'
  content contents.join("\n").concat("\n")
end
