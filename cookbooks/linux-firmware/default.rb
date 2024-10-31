# frozen_string_literal: true

#
# Public Variables
#

node.reverse_merge!({
  linux_firmware: {
    excludes: [],
    includes: [],
  },
})

#
# Minimize
#

if ENV['MINIMIZE_LINUX_FIRMWARE'].eql?('true')
  node.linux_firmware.excludes << '/lib/firmware/*'
  node.linux_firmware.includes << '/lib/firmware/rtl_nic/*'
end

#
# Raspberry Pi
#

if node.target.kernel == 'raspi'
  node.linux_firmware.excludes << '/lib/firmware/nvidia/*'
  node.linux_firmware.excludes << '/lib/firmware/radeon/*'
  node.linux_firmware.excludes << '/lib/firmware/iwlwifi*'
  node.linux_firmware.includes << '/lib/firmware/brcm/*'
  node.linux_firmware.includes << '/lib/firmware/cypress/*'
end

#
# Validate Variables
#

node.validate! do
  {
    linux_firmware: {
      excludes: array_of(string),
      includes: array_of(string),
    },
  }
end

#
# Check Empty Variables
#

if node.linux_firmware.excludes.empty? and node.linux_firmware.includes.empty?
  return
end

#
# Check Distribution
#

unless node[:target][:distribution].match(/^ubuntu$/)
  return
end

#
# [Ex|In]cludes Firmware
#

contents = []

node.linux_firmware.excludes.each do |path|
  contents << "path-exclude #{path}"
end

node.linux_firmware.includes.each do |path|
  contents << "path-include #{path}"
end

file '/etc/dpkg/dpkg.cfg.d/linux-firmware' do
  owner   'root'
  group   'root'
  mode    '0644'
  content "#{contents.join("\n")}\n"
  notifies :run, 'execute[apt-get install -y --reinstall linux-firmware]', :immediately
end

execute 'apt-get install -y --reinstall linux-firmware' do
  action :nothing
end
