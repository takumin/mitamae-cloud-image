# frozen_string_literal: true

#
# Check Distribution
#

unless node[:target][:distribution].match(/^(debian|ubuntu)$/)
  return
end

#
# Package Install
#

package 'live-boot'

#
# Workaround: Systemd /dev/shm error
# https://unix.stackexchange.com/questions/768985/debian-linux-live-system-toram-failed-to-open-dev-shm-device/774297#774297
#

file '/lib/live/boot/9990-toram-todisk.sh' do
  action :edit
  block do |content|
    content.gsub!('dev="/dev/shm"', 'dev="tmpfs"')
  end
end
