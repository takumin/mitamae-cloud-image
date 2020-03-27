# frozen_string_literal: true

#
# Package Install
#

include_recipe File.expand_path('../../minimal', __FILE__)

case node[:platform].to_sym
when :debian
  execute 'aptitude -F %p search \'~pstandard\' | xargs apt-get install -yqq'
when :ubuntu
  package 'ubuntu-standard'
else
  MItamae.logger.info "Ignore standard package installation for this platform: #{node[:platform]}"
end
