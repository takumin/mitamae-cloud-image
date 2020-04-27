# frozen_string_literal: true

#
# Public Variables
#

node[:keyboard]           ||= Hashie::Mash.new
node[:keyboard][:model]   ||= 'pc105'
node[:keyboard][:layout]  ||= 'us'
node[:keyboard][:variant] ||= ''
node[:keyboard][:options] ||= ['ctrl:nocaps']

#
# Validate Variables
#

node.validate! do
  {
    keyboard: {
      model:   string,
      layout:  string,
      variant: string,
      options: array_of(string),
    },
  }
end

#
# Required Packages
#

package 'console-setup'

#
# Keyboard Model
#

file '/etc/default/keyboard' do
  action :edit
  not_if "grep -E '^XKBMODEL=\"#{node[:keyboard][:model]}\"$' /etc/default/keyboard"
  block do |content|
    content.gsub!(/^XKBMODEL=.*$/, "XKBMODEL=\"#{node[:keyboard][:model]}\"")
  end
end

#
# Keyboard Layout
#

file '/etc/default/keyboard' do
  action :edit
  not_if "grep -E '^XKBLAYOUT=\"#{node[:keyboard][:layout]}\"$' /etc/default/keyboard"
  block do |content|
    content.gsub!(/^XKBLAYOUT=.*$/, "XKBLAYOUT=\"#{node[:keyboard][:layout]}\"")
  end
end

#
# Keyboard Variant
#

file '/etc/default/keyboard' do
  action :edit
  not_if "grep -E '^XKBVARIANT=\"#{node[:keyboard][:variant]}\"$' /etc/default/keyboard"
  block do |content|
    content.gsub!(/^XKBVARIANT=.*$/, "XKBVARIANT=\"#{node[:keyboard][:variant]}\"")
  end
end

#
# Keyboard Options
#

file '/etc/default/keyboard' do
  action :edit
  not_if "grep -E '^XKBOPTIONS=\"#{node[:keyboard][:options].join(' ')}\"$' /etc/default/keyboard"
  block do |content|
    content.gsub!(/^XKBOPTIONS=.*$/, "XKBOPTIONS=\"#{node[:keyboard][:options].join(' ')}\"")
  end
end
