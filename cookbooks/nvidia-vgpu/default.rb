# frozen_string_literal: true

#
# Check Role
#

unless node[:target][:role].match?(/-nvidia-vgpu$/)
  return
end

#
# Check Architecture
#

unless node[:target][:architecture].match?(/(?:amd64)$/)
  MItamae.logger.error "nvidia-vgpu: Unsupported architecture: #{node[:kernel][:machine]}"
  exit 1
end

#
# Check Platform
#

unless node[:platform].match?(/(?:debian|ubuntu)$/)
  MItamae.logger.error "nvidia-vgpu: Unsupported platform: #{node[:platform]}"
  exit 1
end

#
# Private Variables
#

case node[:phase]
when :initialize
  base = File.expand_path('../../../.bin', __FILE__)
when :provision
  base = '/'
else
  raise
end

files = Hashie::Mash.new({
  installer: Hashie::Mash.new({
    searchname: 'NVIDIA-Linux-x86_64-*-vgpu-kvm.run',
    version:    '',
    filename:   '',
    filepath:   '',
  }),
  custompatch: Hashie::Mash.new({
    searchname: 'NVIDIA-Linux-x86_64-*-vgpu-kvm.run.patch',
    version:    '',
    filename:   '',
    filepath:   '',
  }),
})

#
# Check Installer
#

files.each do |k, v|
  if Dir.glob(File.expand_path(File.join(base, v.searchname), __FILE__)).empty?
    MItamae.logger.error "nvidia-vgpu: Not found #{v.searchname}"
    exit 1
  end
end

#
# Check Version
#

files.each do |k, v|
  result = run_command("find #{base} -mindepth 1 -maxdepth 1 -type f -name '#{v.searchname}' | sort -Vr | head -n 1")
  raise unless result.success?

  files[k].filepath = result.stdout.chomp.strip
  files[k].filename = File.basename(files[k].filepath)
  files[k].version  = files[k].filename.gsub(/.*-(\d+\.\d+\.\d+)-.*/){$1}
end

unless files.installer.version == files.custompatch.version
  MItamae.logger.error 'nvidia-vgpu: Unmatch Installer and Patch Version'
  exit 1
end

#
# Copy Installer (Initialize Phase)
#

if node[:phase].eql?(:initialize)
  files.each do |k, v|
    target_dir  = node[:target][:directory]
    target_path = File.join(target_dir, v.filename)

    execute "cp #{v.filepath} #{target_path}" do
      not_if "test -f #{target_path}"
    end
  end
end

#
# Running Intaller (Provision Phase)
#

if node[:phase].eql?(:provision)
  #
  # Required Packages
  #

  case node[:platform]
  when 'ubuntu'
    case node[:target][:kernel]
    when 'generic-hwe'
      package "linux-headers-#{node[:target][:kernel]}-#{node[:platform_version]}"
    when 'generic'
      package "linux-headers-#{node[:target][:kernel]}"
    else
      raise
    end
  when 'debian'
    case node[:target][:kernel]
    when 'generic'
      package "linux-headers-#{node[:target][:architecture]}"
    else
      raise
    end
  else
    raise
  end

  #
  # Installer Permission
  #

  file files.installer.filepath do
    owner 'root'
    group 'root'
    mode  '0755'
  end

  #
  # Patch Installer
  #

  # TODO

  # custom_installer = files.installer.filename.gsub(/kvm\.run$/, 'kvm-custom.run')

  # execute "/#{files.installer.filename} --apply-patch /#{files.custompatch.filename}" do
  #   not_if "test -f /#{custom_installer}"
  # end

  #
  # Install NVIDIA vGPU Manager
  #

  # TODO

  # execute "/#{custom_installer} --accept-license --no-ncurses-color"
end
