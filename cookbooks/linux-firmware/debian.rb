# frozen_string_literal: true

#
# Select Packages
#

case node.target.kernel
when /^(?:generic|rt)(?:-backports)?$/
  # network
  node.linux_firmware.packages << 'firmware-realtek'
  node.linux_firmware.packages << 'firmware-intel-misc'
  node.linux_firmware.packages << 'firmware-misc-nonfree'
  node.linux_firmware.packages << 'firmware-bnx2'
  node.linux_firmware.packages << 'firmware-bnx2x'
  node.linux_firmware.packages << 'firmware-qlogic'
  # graphics
  node.linux_firmware.packages << 'firmware-intel-graphics'
  node.linux_firmware.packages << 'firmware-amd-graphics'

  if node.target.role.match?(/desktop/)
    # wireless
    node.linux_firmware.packages << 'firmware-iwlwifi'
    node.linux_firmware.packages << 'firmware-mediatek'
    # sound
    node.linux_firmware.packages << 'firmware-cirrus'
    node.linux_firmware.packages << 'firmware-intel-sound'
    node.linux_firmware.packages << 'firmware-sof-signed'
    # nouveau
    node.linux_firmware.packages << 'firmware-nvidia-graphics' unless node.target.role.match?(/nvidia/)
  end

  # bookworm ships these files in firmware-misc-nonfree, and only
  # bookworm-backports has the split packages
  if node.target.suite == 'bookworm' and !node.target.kernel.end_with?('-backports')
    %w{
      firmware-intel-misc
      firmware-intel-graphics
      firmware-mediatek
      firmware-cirrus
      firmware-nvidia-graphics
    }.each do |pkg|
      node.linux_firmware.packages.delete(pkg)
    end
  end
when /^cloud(?:-backports)?$/
  # no firmware
when 'raspberrypi'
  # raspberrypi installs the firmware for the on-board devices
when 'proxmox'
  # proxmox-default-kernel pulls pve-firmware in
else
  raise
end

#
# Select Options
#

# firmware-misc-nonfree recommends the graphics and mediatek firmware
node.linux_firmware.options << '--no-install-recommends'
