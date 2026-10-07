# frozen_string_literal: true

#
# Get Kernel Version Command
#

GET_KERNEL_VERSION = 'basename "$(find /lib/modules -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)"'

#
# Cleanup Initramfs
#

execute 'find /boot -type f -name "initrd.img-*" | xargs rm -f'

#
# Create Initramfs
#

execute "update-initramfs -c -k \"$(#{GET_KERNEL_VERSION})\"" do
  not_if "test -f \"/boot/initrd.img-$(#{GET_KERNEL_VERSION})\""
end

#
# Remove Cdebootstrap Helper Package
#

package 'cdebootstrap-helper-rc.d' do
  action :remove
end

#
# Upgrade Packages
#

execute 'apt-get -y dist-upgrade'

#
# Cleanup Packages
#

execute 'apt-get -y autoremove --purge'
execute 'apt-get -y clean'

#
# Restore Apt Repository
#

# The build-time mirrors (APT_REPO_URL_*) are only reachable from the build
# host, so rewrite every apt_repository declared so far to its default_uri;
# the root recipes are not attached to the recipe root until all of them are
# compiled, so walk the tree down from the top of the current recipe
collect_apt_repositories = lambda do |nodes|
  nodes.flat_map do |child|
    case child
    when ::MItamae::Recipe, ::MItamae::RecipeFromDefinition
      collect_apt_repositories.call(child.children)
    when ::MItamae::Plugin::Resource::AptRepository
      [child]
    else
      []
    end
  end
end

top_recipe = @recipe
top_recipe = top_recipe.parent while top_recipe.parent.is_a?(::MItamae::Recipe)

collect_apt_repositories.call(top_recipe.children).each do |repository|
  next unless Array(repository.attributes.action).include?(:create)
  next unless repository.attributes.entry.any? { |repo| repo.mirror_uri.to_s.match?(/^(?:file|https?):\/\//) }

  apt_repository repository.resource_name do
    path   repository.attributes.path
    header repository.attributes.header if repository.attributes.header
    footer repository.attributes.footer if repository.attributes.footer
    entry  repository.attributes.entry.map { |repo|
      repo.each_with_object({}) { |(k, v), h| h[k] = v unless k.to_s.match?(/^(?:mirror_)?uri$/) }
    }
  end
end

#
# Cleanup Apt Cache
#

execute 'rm -fr /var/lib/apt/lists' do
  only_if 'test "$(find /var/lib/apt/lists -mindepth 1 -maxdepth 1 -type f | wc -l)" -gt 1'
  notifies :create, 'directory[/var/lib/apt/lists]'
  notifies :create, 'file[/var/lib/apt/lists/lock]'
end

directory '/var/lib/apt/lists' do
  action :nothing
  owner 'root'
  group 'root'
  mode  '0755'
end

file '/var/lib/apt/lists/lock' do
  action :nothing
  owner 'root'
  group 'root'
  mode  '0640'
end

file '/etc/apt/apt.conf.d/cache-clean' do
  action :delete
end

#
# Workaround: Remove Unused Kernel/Initramfs Files
#

%w{
  /vmlinuz.old
  /initrd.img.old
  /boot/vmlinuz.old
  /boot/initrd.img.old
}.each do |f|
  file f do
    action :delete
  end
end
