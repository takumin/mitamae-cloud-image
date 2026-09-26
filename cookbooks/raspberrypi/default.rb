# frozen_string_literal: true

#
# Check Distribution
#

unless node[:target][:distribution].match(/^(?:debian|ubuntu)$/)
  return
end

#
# Check Kernel
#

unless node[:target][:kernel].match(/^(?:raspberrypi|raspi)$/)
  return
end

#
# Select Distribution
#

include_recipe node.platform

#
# Device Groups
#

%w[gpio i2c spi].each do |name|
  execute "groupadd -f -r #{name}" do
    not_if "getent group #{name}"
  end
end

#
# Kernel Modules
#
# /dev/i2c-* needs i2c-dev, which nothing loads automatically. spidev is
# loaded by its modalias once dtparam=spi=on is set in config.txt.
#

file '/etc/modules-load.d/i2c-dev.conf' do
  owner   'root'
  group   'root'
  mode    '0644'
  content "i2c-dev\n"
end

#
# Udev Rules
#
# Taken from raspberrypi-sys-mods (RPi-Distro/raspberrypi-sys-mods@7959bb7)
# instead of installing the package, which also changes journald, the
# watchdog and SSH host keys. 99-com.rules reads device tree aliases with
# cat instead of strings, so that binutils is not needed.
#

%w[
  10-vc.rules
  15-i2c-modprobe.rules
  60-dma-heap.rules
  60-gpiochip4.rules
  60-i2c-aliases.rules
  60-piolib.rules
  99-com.rules
].each do |name|
  remote_file "/usr/lib/udev/rules.d/#{name}" do
    owner  'root'
    group  'root'
    mode   '0644'
    source "files/#{name}"
  end
end

directory '/usr/lib/raspberrypi-sys-mods' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/usr/lib/raspberrypi-sys-mods/i2cprobe' do
  owner  'root'
  group  'root'
  mode   '0755'
  source 'files/i2cprobe'
end
