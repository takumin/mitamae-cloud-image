# frozen_string_literal: true

#
# Check Role
#

if node[:target][:role].match(/minimal/)
  return
end

#
# Package Install
#

case node[:platform].to_sym
when :debian, :ubuntu
  # apt
  package 'debconf'
  # hardware
  package 'dmidecode'
  package 'laptop-detect'
  package 'pciutils'
  package 'usbutils'
  package 'lshw'
  # networking
  package 'netbase'
  package 'ethtool'
  package 'iproute2'
  package 'iputils-ping'
  package 'netcat-openbsd'
  # utility
  package 'bash-completion'
  package 'bind9-dnsutils'
  package 'diffutils'
  package 'file'
  package 'htop'
  package 'less'
  package 'lsof'
  package 'nmap'
  package 'patch'
  package 'procps'
  package 'psmisc'
  package 'socat'
  package 'tree'
  package 'vim'
when :arch
  # TODO
else
  MItamae.logger.info "Ignore standard package installation for this platform: #{node[:platform]}"
end

#
# Skelton Files
#

contents = <<__EOF__
alias ls="ls --color=auto --show-control-chars --group-directories-first --time-style='+%Y-%m-%d %H:%M:%S'"

alias la="ls -a"
alias lf="ls -FA"
alias li="ls -ai"
alias ll="ls -FAlh"

alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

alias free="free -h"

alias du="du -h"
alias df="df -h"

alias top="htop"

alias htop="htop -t"
__EOF__

file '/etc/skel/.bash_aliases' do
  owner   'root'
  group   'root'
  mode    '0644'
  content contents
end
