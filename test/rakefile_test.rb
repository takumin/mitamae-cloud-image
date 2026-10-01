# frozen_string_literal: true

require_relative 'test_helper'

require 'json'
require 'open3'

# Runs the tasks the CI workflow calls in a separate rake process
class RakefileTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)

  def rake(*args, env: {})
    out, status = Open3.capture2(env, RbConfig.ruby, Gem.bin_path('rake', 'rake'), '-f', File.join(ROOT, 'Rakefile'), *args, chdir: ROOT)
    assert status.success?, "rake #{args.join(' ')} failed"
    out
  end

  def test_github_actions_all
    matrix = JSON.parse(rake('github:actions:all'))

    refute_empty matrix
    assert_includes matrix, {
      'name'   => 'ubuntu:resolute:raspberrypi:arm64:desktop',
      'dir'    => 'ubuntu/resolute/raspberrypi/arm64/desktop',
      'runner' => 'ubuntu-26.04-arm',
    }
    names = matrix.map { |t| t['name'] }
    assert(names.none? { |n| n.include?('nvidia-legacy') })

    without_vgpu = JSON.parse(rake('github:actions:all', env: { 'APT_REPO_PPA_NVIDIA_VGPU_URL' => '' }))
    assert_equal names.reject { |n| n.include?('nvidia-vgpu') }, without_vgpu.map { |t| t['name'] }
  end

  def test_github_actions_publish
    assert_equal "PUBLISH=true\n", rake('github:actions:publish:debian:trixie:raspberrypi:arm64:kodi')
    assert_equal "PUBLISH=false\n", rake('github:actions:publish:ubuntu:noble:generic:amd64:server')
  end

  def test_every_target_has_the_build_tasks
    tasks = rake('-AT').lines.map { |l| l.split[1] }
    all = tasks.grep(/:all\z/).reject { |t| t.start_with?('github:') }

    refute_empty all
    all.each do |t|
      prefix = t.delete_suffix(':all')
      %w{initialize provision finalize}.each do |phase|
        assert_includes tasks, "#{prefix}:#{phase}"
      end
    end
  end
end
