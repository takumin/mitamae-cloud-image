# frozen_string_literal: true

#
# Public Variables
#

node.reverse_merge!({
  nvidia_legacy: {
    installer: {
      version: '580.178.04',
      sha256:  '1833c8c5c53481dfab46df442c3de26ec5d4c35084e03d94ad93746d29899750',
    },
  },
})

node.reverse_merge!({
  nvidia_legacy: {
    installer: {
      url: File.join(
        'https://download.nvidia.com/XFree86/Linux-x86_64',
        node[:nvidia_legacy][:installer][:version],
        "NVIDIA-Linux-x86_64-#{node[:nvidia_legacy][:installer][:version]}-no-compat32.run",
      ),
    },
  },
})

#
# Validate Variables
#

node.validate! do
  {
    nvidia_legacy: {
      installer: {
        version: match(/^[0-9]+\.[0-9]+\.[0-9]+$/),
        sha256:  match(/^[0-9a-f]{64}$/),
        url:     match(/^https?:\/\//),
      },
    },
  }
end

#
# Private Variables
#

version   = node[:nvidia_legacy][:installer][:version]
installer = "/tmp/NVIDIA-Linux-x86_64-#{version}.run"

# The image ships a single kernel, which is not the running one
kernel_version = '"$(basename "$(find /lib/modules -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)")"'

#
# Required Packages
#

include_recipe File.expand_path('../linux-headers', File.dirname(__FILE__))

package 'build-essential'
package 'dkms'
package 'pkg-config'
package 'libglvnd0'
package 'libvulkan1'

if node[:target][:role].match?(/^desktop-/)
  package 'libegl1'
  package 'libgl1'
  package 'libgles2'
  package 'libglx0'
  package 'libopengl0'
end

#
# Blacklist Nouveau
#

file '/etc/modprobe.d/nvidia-blacklists-nouveau.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  content [
    'blacklist nouveau',
    'options nouveau modeset=0',
    '',
  ].join("\n")
end

#
# Module Options
#

# The installer leaves kernel mode setting off, which nvidia-vaapi-driver
# and Wayland require; GDM also falls back to Xorg unless video memory is
# preserved across suspend
file '/etc/modprobe.d/nvidia-options.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  content [
    'options nvidia-drm modeset=1',
    'options nvidia NVreg_PreserveVideoMemoryAllocations=1',
    '',
  ].join("\n")
end

#
# Download Installer
#

execute "curl -fsSLo #{installer} #{node[:nvidia_legacy][:installer][:url]}" do
  not_if "test -d /usr/src/nvidia-#{version}"
end

execute "echo '#{node[:nvidia_legacy][:installer][:sha256]}  #{installer}' | sha256sum -c -" do
  not_if "test -d /usr/src/nvidia-#{version}"
end

#
# Install Driver
#

# Pascal GPUs are not supported by the open kernel modules. The build
# host may have its own nvidia module loaded, which is visible from the
# chroot but irrelevant to the image, so skip every running system check
options = [
  '--silent',
  '--dkms',
  '--kernel-module-type=proprietary',
  "--kernel-name=#{kernel_version}",
  '--skip-module-load',
  '--allow-installation-with-running-driver',
  '--no-nouveau-check',
  '--no-x-check',
  '--no-backup',
  '--no-rpms',
  '--no-check-for-alternate-installs',
  '--no-install-libglvnd',
  '--glvnd-egl-config-path=/usr/share/glvnd/egl_vendor.d',
  '--tmpdir=/tmp',
]

if node[:target][:role].match?(/^server-/)
  options << '--no-opengl-files'
end

execute "sh #{installer} #{options.join(' ')}" do
  not_if "test -d /usr/src/nvidia-#{version}"
  notifies :run, 'execute[strip nvidia modules]', :immediately
  notifies :run, 'execute[remove nvidia build logs]', :immediately
end

#
# Reduce Image Size
#

# The modules are built with debug info and DKMS keeps a copy of them;
# strip both alike so that dkms status still sees them as identical
execute 'strip nvidia modules' do
  command [
    'strip --strip-debug',
    "/lib/modules/#{kernel_version}/updates/dkms/nvidia*.ko",
    "/var/lib/dkms/nvidia/#{version}/#{kernel_version}/x86_64/module/nvidia*.ko",
  ].join(' ')
  action :nothing
end

execute 'remove nvidia build logs' do
  command [
    'rm -f',
    '/var/log/nvidia-installer.log',
    "/var/lib/dkms/nvidia/#{version}/#{kernel_version}/x86_64/log/make.log",
  ].join(' ')
  action :nothing
end

#
# Cleanup Installer
#

file installer do
  action :delete
end
