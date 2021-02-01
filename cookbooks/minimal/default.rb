# frozen_string_literal: true

#
# Package Install
#

case node[:platform].to_sym
when :debian
  # Workaround 'mail-transport-agent'
  package 'nullmailer'

  # https://wiki.debian.org/tasksel
  # https://unix.stackexchange.com/questions/227303/can-a-debian-packages-priority-field-be-used-for-selection-for-install
  # https://github.com/szepeviktor/debian-server-tools/blob/master/debian-setup/debian-image-normalize.sh
  package 'aptitude'
  execute 'aptitude -F %p search \'~E\' | xargs apt-get install -yqq'
  execute 'aptitude -F %p search \'~prequired\' | xargs apt-get install -yqq'
  execute 'aptitude -F %p search \'~pimportant\' | xargs apt-get install -yqq'
when :ubuntu
  package 'ubuntu-minimal'
when :arch
  package 'base'
else
  MItamae.logger.info "Ignore minimal package installation for this platform: #{node[:platform]}"
end
