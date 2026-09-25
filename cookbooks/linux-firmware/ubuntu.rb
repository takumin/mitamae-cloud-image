# frozen_string_literal: true

#
# Select Packages
#

# linux-image-{generic,raspi} depend on linux-firmware, which pulls every
# linux-firmware-* package; linux-firmware-minimal provides it without them
case node.target.kernel
when /^(?:generic|lowlatency)(?:-hwe)?$/
  node.linux_firmware.packages << 'linux-firmware-minimal'
  # network
  node.linux_firmware.packages << 'linux-firmware-realtek'
  node.linux_firmware.packages << 'linux-firmware-intel-misc'
  node.linux_firmware.packages << 'linux-firmware-misc'
  node.linux_firmware.packages << 'linux-firmware-qlogic'
  # graphics
  node.linux_firmware.packages << 'linux-firmware-intel-graphics'
  node.linux_firmware.packages << 'linux-firmware-amd-graphics'

  if node.target.role.match?(/desktop/)
    # wireless
    node.linux_firmware.packages << 'linux-firmware-intel-wireless'
    node.linux_firmware.packages << 'linux-firmware-mediatek'
    # sound
    node.linux_firmware.packages << 'firmware-sof-signed'
    # nouveau
    node.linux_firmware.packages << 'linux-firmware-nvidia-graphics' unless node.target.role.match?(/nvidia/)
  end
when 'raspi'
  # linux-firmware-raspi installed by linux-kernel covers the on-board devices
  node.linux_firmware.packages << 'linux-firmware-minimal'
when /^virtual(?:-hwe)?$/
  # no firmware
else
  raise
end

#
# Select Options
#

# linux-firmware-minimal recommends every linux-firmware-* package
node.linux_firmware.options << '--no-install-recommends'
