# frozen_string_literal: true

#
# Public Variables
#

node.reverse_merge!({
  autologin: {
    default: {
      service: 'getty',
      getty:   '/sbin/agetty',
      user:    'root',
      port:    'tty1',
      term:    'linux',
      baud:    [],
      opts:    ['--noclear'],
    },
    serial: {
      service: 'serial-getty',
      getty:   '/sbin/agetty',
      user:    'root',
      port:    'ttyS0',
      term:    'linux',
      baud:    [115200,38400,9600],
      opts:    ['--noclear', '--keep-baud'],
    },
  },
})

#
# Validate Variables
#

node.autologin.keys.each do |k|
  node.validate! do
    {
      autologin: {
        "#{k}": {
          service: match(/^(?:serial-)?getty$/),
          getty:   string,
          user:    match(/^(?:[a-zA-Z0-9]*)$/),
          port:    match(/^(?:tty[a-zA-Z0-9]+)$/),
          term:    string,
          baud:    array_of(integer),
          opts:    array_of(string),
        },
      },
    }
  end
end

#
# Disable automatic terminal login when in desktop role
#

if node.target.role.match(/desktop/)
  return
end

#
# Loop AutoLogin Profiles
#

node.autologin.values.each do |autologin|
  #
  # Build Command Options
  #

  agetty_args = [
    '--autologin', autologin.user,
  ]

  unless autologin.opts.empty?
    autologin.opts.each do |opt|
      agetty_args.push(opt)
    end
  end

  agetty_args.push('%I')

  unless autologin.baud.empty?
    agetty_args.push(autologin.baud.map{|b| b.to_s}.join(','))
  end

  agetty_args.push(autologin.term)

  #
  # Override Systemd Directory
  #

  directory "/etc/systemd/system/#{autologin.service}@#{autologin.port}.service.d" do
    owner 'root'
    group 'root'
    mode  '0755'
  end

  #
  # Override Systemd Service
  #

  file "/etc/systemd/system/#{autologin.service}@#{autologin.port}.service.d/autologin.conf" do
    owner 'root'
    group 'root'
    mode  '0644'
    content [
      '[Service]',
      'Type=idle',
      'ExecStart=',
      "ExecStart=-#{autologin.getty} #{agetty_args.join(' ')}",
    ].join("\n")
  end

  file "/etc/systemd/system/#{autologin.service}@#{autologin.port}.service.d/noclear.conf" do
    owner 'root'
    group 'root'
    mode  '0644'
    content [
      '[Service]',
      'TTYVTDisallocate=no',
    ].join("\n")
  end

  #
  # Enable Systemd Service
  #

  service "#{autologin.service}@#{autologin.port}.service" do
    action :enable
  end
end
