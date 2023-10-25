# frozen_string_literal: true

#
# Public Variables
#

node[:timezone] ||= 'UTC'

#
# Default Variables
#

if ENV['TIMEZONE'].is_a?(String) and !ENV['TIMEZONE'].empty?
  node[:timezone] = ENV['TIMEZONE']
end

#
# Select Distribution
#

package 'tzdata'

#
# Configuration Timezone
#

file '/etc/timezone' do
  owner   'root'
  group   'root'
  mode    '0644'
  content "#{node[:timezone]}\n"
end

link '/etc/localtime'  do
  to "/usr/share/zoneinfo/#{node[:timezone]}"
  force true
end

if node[:platform].match(/^(?:debian|ubuntu)$/)
  execute 'dpkg-reconfigure --frontend noninteractive tzdata' do
    action :nothing

    subscribes :run, 'file[/etc/timezone]'
    subscribes :run, 'link[/etc/localtime]'
  end
end
