# frozen_string_literal: true

require_relative 'test_helper'

class ProfileTest < Minitest::Test
  Profile = MitamaeCloudImage::Profile
  Targets = MitamaeCloudImage::Targets

  def target(kernel, architecture)
    Targets.build(
      'distribution' => 'debian',
      'suite'        => 'trixie',
      'kernel'       => kernel,
      'architecture' => architecture,
      'role'         => 'server',
    )
  end

  def test_build_adds_the_directory_to_a_copy_of_the_target
    t = target('generic', 'amd64')

    data = Profile.build(t, directory: '/mnt/rootfs')

    assert_equal t.merge('directory' => '/mnt/rootfs'), data['target']
    refute data['target'].equal?(t)
    refute t.key?('directory')
    refute data.key?('autologin')
  end

  def test_build_enables_serial_autologin_on_raspberrypi
    data = Profile.build(target('raspberrypi', 'arm64'), directory: '/mnt/rootfs')

    assert_equal 'ttyS0', data.dig('autologin', 'serial', 'port')
    assert_equal [115200, 38400, 9600], data.dig('autologin', 'serial', 'baud')
  end

  def test_write
    Dir.mktmpdir do |dir|
      path = File.join(dir, '.bin', 'profile.yaml')
      data = Profile.build(target('raspberrypi', 'arm64'), directory: '/mnt/rootfs')

      Profile.write(path, data)

      assert_equal data, YAML.load_file(path)
    end
  end
end
