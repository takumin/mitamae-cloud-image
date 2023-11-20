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
# Required Packages
#

package 'bash'
package 'wget'
package 'ca-certificates'

#
# Autologin Script
#

contents = <<~__EOF__
# ~/.profile: executed by Bourne-compatible login shells.

mesg n 2> /dev/null || true

if [ "$BASH" ]; then
	if [ -f ~/.bashrc ]; then
		. ~/.bashrc
	fi
fi

for cmdline in $(cat /proc/cmdline); do
	case "${cmdline}" in
		script=*)
			script="${cmdline#script=}"
			;;
	esac
done

if [ -n "${script:-}" ]; then
	if echo "${script}" | grep -qsE '^https?://'; then
		wget -O /tmp/livescript "${script}" 2>&1 | tee /var/log/livescript.log
		bash /tmp/livescript 2>&1 | tee -a /var/log/livescript.log
	fi
fi
__EOF__

file '/root/.profile' do
  owner   'root'
  group   'root'
  mode    '0600'
  content contents
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
    ].join("\n").concat("\n")
  end

  file "/etc/systemd/system/#{autologin.service}@#{autologin.port}.service.d/noclear.conf" do
    owner 'root'
    group 'root'
    mode  '0644'
    content [
      '[Service]',
      'TTYVTDisallocate=no',
    ].join("\n").concat("\n")
  end

  file "/etc/systemd/system/#{autologin.service}@#{autologin.port}.service.d/cloudinit.conf" do
    owner 'root'
    group 'root'
    mode  '0644'
    content [
      '[Unit]',
      'After=cloud-init.target',
    ].join("\n").concat("\n")
  end

  #
  # Enable Systemd Service
  #

  service "#{autologin.service}@#{autologin.port}.service" do
    action :enable
  end
end
