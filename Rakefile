# frozen_string_literal: true

require 'json'
require 'rake/testtask'

require_relative 'lib/mitamae_cloud_image'

LOG_LEVEL = ENV['LOG_LEVEL'] || 'info'

# qemu-user emulates pointer authentication with QARMA5 by default, which is
# extremely slow for binaries built with branch protection
ENV['QEMU_CPU'] ||= 'max,pauth-impdef=on'

BIN_DIR = File.expand_path('.bin', __dir__)

def commands(chroot_dir)
  MitamaeCloudImage::Commands.new(
    root:         __dir__,
    chroot_dir:   chroot_dir,
    log_level:    LOG_LEVEL,
    preserve_env: MitamaeCloudImage::Commands.sudo_preserve_env,
  )
end

def run_steps(steps)
  steps.each do |step|
    abort('failed command') unless MitamaeCloudImage::Shell.run(step.command, chroot: step.chroot)
  end
end

targets = MitamaeCloudImage::Targets.all

targets.each do |target|
  namespace MitamaeCloudImage::Targets.name(target) do
    chroot_dir = MitamaeCloudImage::Targets.chroot_dir(target)

    task :initialize do
      MitamaeCloudImage::Mitamae.install(File.join(BIN_DIR, 'mitamae'))
      profile = MitamaeCloudImage::Profile.build(target, directory: chroot_dir)
      MitamaeCloudImage::Profile.write(File.join(BIN_DIR, 'profile.yaml'), profile)

      run_steps(commands(chroot_dir).initialize_phase)
    end

    task :provision do
      run_steps(commands(chroot_dir).provision_phase)
    end

    task :finalize do
      run_steps(commands(chroot_dir).finalize_phase)
    end

    desc target.values.join(' ')
    task :all => [
      :initialize,
      :provision,
      :finalize,
    ]
  end
end

namespace :github do
  namespace :actions do
    task :all do
      puts JSON.dump(MitamaeCloudImage::Targets.github_actions_matrix(targets))
    end

    targets.each do |target|
      task "publish:#{MitamaeCloudImage::Targets.name(target)}" do
        puts "PUBLISH=#{MitamaeCloudImage::Targets.publish?(target)}"
      end
    end
  end
end

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = true
end
