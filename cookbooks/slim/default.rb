# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match?(/minimal/)
  return
end

unless node[:platform].match?(/^(?:debian|ubuntu)$/)
  return
end

#
# Private Variables
#

# Same as the "slim" variant of the Debian base image
# https://github.com/debuerreotype/debuerreotype/blob/master/scripts/.slimify-excludes
excludes = [
  '/usr/share/doc/*',
  '/usr/share/info/*',
  '/usr/share/linda/*',
  '/usr/share/lintian/overrides/*',
  '/usr/share/locale/*',
  '/usr/share/man/*',
  '/usr/share/doc/kde/HTML/*/*',
  '/usr/share/gnome/help/*/*',
  '/usr/share/omf/*/*-*.emf',
]

# https://github.com/debuerreotype/debuerreotype/blob/master/scripts/.slimify-includes
includes = [
  '/usr/share/doc/*/copyright',
  '/usr/share/doc/kde/HTML/C/*',
  '/usr/share/gnome/help/*/C/*',
  '/usr/share/locale/all_languages',
  '/usr/share/locale/currency/*',
  '/usr/share/locale/l10n/*',
  '/usr/share/locale/languages',
  '/usr/share/locale/locale.alias',
  '/usr/share/omf/*/*-C.emf',
]

#
# Dpkg Path Filter
#

# Placed before the other recipes install packages, so dpkg skips these files from then on
file '/etc/dpkg/dpkg.cfg.d/slim' do
  owner   'root'
  group   'root'
  mode    '0644'
  content [
    '# Many files which are normally unnecessary in the minimal image are excluded,',
    '# and this configuration file keeps them that way.',
    '',
    excludes.map { |path| "path-exclude #{path}" },
    '',
    includes.map { |path| "path-include #{path}" },
  ].flatten.join("\n").concat("\n")
end

#
# Remove Excluded Files
#

# The packages installed by debootstrap already have these files, so remove
# them as dpkg would: files matching an include stay, and the directories
# left empty and the dangling symlinks go after them
match_includes = includes.map { |path| "-path '#{path}'" }.join(' -o ')

excludes.group_by { |path| path[/\A[^*?\[]*\//].chomp('/') }.each do |base, paths|
  match_excludes = paths.map { |path| "-path '#{path}'" }.join(' -o ')
  find_excluded  = "find #{base} -mindepth 1 \\( #{match_excludes} \\) -not \\( -type d -o -type l \\) -not \\( #{match_includes} \\)"

  execute "remove excluded files in #{base}" do
    command <<~__EOF__
      #{find_excluded} -exec rm -f {} +
      while [ -n "$(find #{base} -depth -mindepth 1 \\( -type d -empty -o -xtype l \\) -exec rm -rf {} \\; -print)" ]; do :; done
    __EOF__
    only_if "test -d #{base} && test -n \"$(#{find_excluded} -print -quit)\""
  end
end

#
# Workaround: Keep Manual Page Directories
#

# The postinst of some packages registers manual pages as alternatives,
# and fails when their directories are missing
# https://github.com/debuerreotype/debuerreotype/issues/10
(1..8).each do |n|
  directory "/usr/share/man/man#{n}" do
    owner 'root'
    group 'root'
    mode  '0755'
  end
end
