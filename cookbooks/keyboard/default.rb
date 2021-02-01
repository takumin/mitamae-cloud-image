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
# Select Distribution
#

case node[:platform]
when 'debian', 'ubuntu'
  include_recipe 'debian.rb'
when 'arch'
  include_recipe 'arch.rb'
else
  raise
end
