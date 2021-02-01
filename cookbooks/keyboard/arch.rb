# #
# # Keyboard Model
# #
# 
# file '/etc/vconsole.conf' do
#   action :edit
#   not_if "grep -E '^XKBMODEL=\"#{node[:keyboard][:model]}\"$' /etc/vconsole.conf"
#   block do |content|
#     content.gsub!(/^XKBMODEL=.*$/, "XKBMODEL=\"#{node[:keyboard][:model]}\"")
#   end
# end
# 
# #
# # Keyboard Layout
# #
# 
# file '/etc/vconsole.conf' do
#   action :edit
#   not_if "grep -E '^XKBLAYOUT=\"#{node[:keyboard][:layout]}\"$' /etc/vconsole.conf"
#   block do |content|
#     content.gsub!(/^XKBLAYOUT=.*$/, "XKBLAYOUT=\"#{node[:keyboard][:layout]}\"")
#   end
# end
# 
# #
# # Keyboard Variant
# #
# 
# file '/etc/vconsole.conf' do
#   action :edit
#   not_if "grep -E '^XKBVARIANT=\"#{node[:keyboard][:variant]}\"$' /etc/vconsole.conf"
#   block do |content|
#     content.gsub!(/^XKBVARIANT=.*$/, "XKBVARIANT=\"#{node[:keyboard][:variant]}\"")
#   end
# end
# 
# #
# # Keyboard Options
# #
# 
# file '/etc/vconsole.conf' do
#   action :edit
#   not_if "grep -E '^XKBOPTIONS=\"#{node[:keyboard][:options].join(' ')}\"$' /etc/vconsole.conf"
#   block do |content|
#     content.gsub!(/^XKBOPTIONS=.*$/, "XKBOPTIONS=\"#{node[:keyboard][:options].join(' ')}\"")
#   end
# end
