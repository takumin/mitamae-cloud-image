# frozen_string_literal: true

#
# Check Distribution
#

unless node[:target][:distribution].match(/^(?:debian|ubuntu)$/)
  return
end

#
# Check Role
#

unless node[:target][:role].match(/desktop/)
  return
end

#
# Public Variables
#

node[:kimpanel]        ||= Hashie::Mash.new
node[:kimpanel][:url]  ||= 'https://github.com/wengxt/gnome-shell-extension-kimpanel'
node[:kimpanel][:uuid] ||= 'kimpanel@kde.org'

# Upstream publishes no releases and every commit supports only a narrow range of GNOME Shell versions, so pin
# the newest commit whose metadata.json.in lists the GNOME Shell of each suite
node[:kimpanel][:commit]            ||= Hashie::Mash.new
node[:kimpanel][:commit][:bookworm] ||= '78f27b676119057c787525eef704662414bc66b5' # GNOME 43
node[:kimpanel][:commit][:trixie]   ||= 'b1e7718f445666cbe4e19ead8422f316e8cb3e39' # GNOME 48
node[:kimpanel][:commit][:noble]    ||= '7c7cbfd5362e1dcfb48dfc19814f9e66db445d09' # GNOME 46
node[:kimpanel][:commit][:resolute] ||= 'b1e7718f445666cbe4e19ead8422f316e8cb3e39' # GNOME 50

#
# Validate Variables
#

node.validate! do
  {
    kimpanel: {
      url:    match(/^https:\/\//),
      uuid:   string,
      commit: {
        bookworm: match(/^[0-9a-f]{40}$/),
        trixie:   match(/^[0-9a-f]{40}$/),
        noble:    match(/^[0-9a-f]{40}$/),
        resolute: match(/^[0-9a-f]{40}$/),
      },
    },
  }
end

#
# Private Variables
#

commit        = node[:kimpanel][:commit][node[:target][:suite]]
archive_url   = "#{node[:kimpanel][:url]}/archive/#{commit}.tar.gz"
archive_path  = '/tmp/kimpanel.tar.gz'
source_dir    = '/tmp/kimpanel'
extension_dir = "/usr/share/gnome-shell/extensions/#{node[:kimpanel][:uuid]}"
schema_name   = 'org.gnome.shell.extensions.kimpanel.gschema.xml'

#
# Required Packages
#

# msgfmt compiles the translations
package 'gettext'

#
# Download Archive
#

execute "curl -fsSLo #{archive_path} #{archive_url}" do
  not_if "test -f #{archive_path}"
end

#
# Extract Archive
#

directory source_dir do
  owner 'root'
  group 'root'
  mode  '0755'
end

execute "tar -xf #{archive_path} -C #{source_dir} --strip-components=1" do
  not_if "test -f #{source_dir}/metadata.json.in"
end

#
# Install Extension
#

# Mirror the install rules of the upstream CMakeLists.txt without pulling cmake and zip into the image
directory extension_dir do
  owner 'root'
  group 'root'
  mode  '0755'
end

execute "install -m 0644 #{source_dir}/*.js #{source_dir}/stylesheet.css #{extension_dir}/" do
  not_if "test -f #{extension_dir}/extension.js"
end

execute "sed 's|@localedir@|/usr/share/locale|' #{source_dir}/metadata.json.in > #{extension_dir}/metadata.json" do
  not_if "test -f #{extension_dir}/metadata.json"
end

execute 'install kimpanel translations' do
  command <<~__EOF__
    for po in #{source_dir}/po/*.po; do
      lang="$(basename "${po}" .po)"
      install -d -m 0755 "/usr/share/locale/${lang}/LC_MESSAGES"
      msgfmt -o "/usr/share/locale/${lang}/LC_MESSAGES/gnome-shell-extensions-kimpanel.mo" "${po}"
    done
  __EOF__
  not_if 'test -f /usr/share/locale/ja/LC_MESSAGES/gnome-shell-extensions-kimpanel.mo'
end

# Install the schema system wide as the Debian package does, which every GNOME Shell version falls back to
execute "install -m 0644 #{source_dir}/schemas/#{schema_name} /usr/share/glib-2.0/schemas/" do
  not_if "test -f /usr/share/glib-2.0/schemas/#{schema_name}"
  notifies :run, 'execute[glib-compile-schemas /usr/share/glib-2.0/schemas]'
end

#
# Enable Extension
#

# No other override sets enabled-extensions, and the extensions of the Ubuntu session mode are enabled apart
# from this key
file '/usr/share/glib-2.0/schemas/99_kimpanel.gschema.override' do
  owner 'root'
  group 'root'
  mode  '0644'
  content [
    '[org.gnome.shell]',
    "enabled-extensions=['#{node[:kimpanel][:uuid]}']",
  ].join("\n").concat("\n")
  notifies :run, 'execute[glib-compile-schemas /usr/share/glib-2.0/schemas]'
end

execute 'glib-compile-schemas /usr/share/glib-2.0/schemas' do
  action :nothing
end

#
# Cleanup Archive
#

file archive_path do
  action :delete
end

execute "rm -rf #{source_dir}" do
  only_if "test -d #{source_dir}"
end
