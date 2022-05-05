# frozen_string_literal: true

#
# Check Role
#

if node[:target][:role].match(/minimal/)
  return
end

#
# Public Variables
#

node[:locale]              ||= Hashie::Mash.new
node[:locale][:availables] ||= [
  'ja_JP.UTF-8 UTF-8',
  'en_US.UTF-8 UTF-8'
]
node[:locale][:defaults]   ||= Hashie::Mash.new({
  LANG: 'ja_JP.UTF-8',
})

#
# Private Variables
#

availables = node[:locale][:availables].map {|locale|
  locale.gsub(/\s+.*$/, '')
}.uniq.sort

#
# Validate Variables
#

node.validate! do
  {
    locale: {
      availables: array_of(string),
      defaults: {
        LANG:              optional(match(/^(?:#{availables.join('|')})$/)),
        LANGUAGE:          optional(match(/^(?:#{availables.join('|')})$/)),
        LC_CTYPE:          optional(match(/^(?:#{availables.join('|')})$/)),
        LC_NUMERIC:        optional(match(/^(?:#{availables.join('|')})$/)),
        LC_TIME:           optional(match(/^(?:#{availables.join('|')})$/)),
        LC_COLLATE:        optional(match(/^(?:#{availables.join('|')})$/)),
        LC_MONETARY:       optional(match(/^(?:#{availables.join('|')})$/)),
        LC_MESSAGES:       optional(match(/^(?:#{availables.join('|')})$/)),
        LC_PAPER:          optional(match(/^(?:#{availables.join('|')})$/)),
        LC_NAME:           optional(match(/^(?:#{availables.join('|')})$/)),
        LC_ADDRESS:        optional(match(/^(?:#{availables.join('|')})$/)),
        LC_TELEPHONE:      optional(match(/^(?:#{availables.join('|')})$/)),
        LC_MEASUREMENT:    optional(match(/^(?:#{availables.join('|')})$/)),
        LC_IDENTIFICATION: optional(match(/^(?:#{availables.join('|')})$/)),
        LC_ALL:            optional(match(/^(?:#{availables.join('|')})$/)),
      },
    },
  }
end

#
# Required Packages
#

case node[:platform]
when 'debian', 'ubuntu'
  package 'locales'
  package 'locales-all'
when 'arch'
  # nothing...
else
  raise
end

#
# Availables Locale
#

node[:locale][:availables].each do |locale|
  file '/etc/locale.gen' do
    action :edit
    not_if "grep -E '^#{locale}$' /etc/locale.gen"
    block do |content|
      content.gsub!(/^#?\s?#{locale}\s+?$/, "#{locale}")
    end
    notifies :run, 'execute[locale-gen]'
  end
end

#
# Event Handler
#

execute 'locale-gen' do
  action :nothing
end

#
# Select Locale
#

if node[:platform].match(/^(?:debian|ubuntu)$/)
  node[:locale][:defaults].each do |k, v|
    execute "update-locale #{k}=#{v}" do
      not_if "grep -E '^#{k}=#{v}$' /etc/default/locale"
    end
  end
end
