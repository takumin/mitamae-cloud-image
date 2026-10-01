# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module MitamaeCloudImage
  # The node attributes passed to mitamae with '-y'
  module Profile
    SERIAL_AUTOLOGIN = {
      'serial' => {
        'service' => 'serial-getty',
        'getty'   => '/sbin/agetty',
        'port'    => 'ttyS0',
        'user'    => 'root',
        'term'    => 'linux',
        'baud'    => [115200,38400,9600],
        'opts'    => ['--keep-baud', '--flow-control'],
      }
    }.freeze

    module_function

    def build(target, directory:)
      # Copy the target: the tasks build their paths from target.values, which must not gain the directory
      data = { 'target' => target.dup }
      if target['kernel'].eql?('raspberrypi')
        data['autologin'] = Marshal.load(Marshal.dump(SERIAL_AUTOLOGIN))
      end
      data['target']['directory'] = directory
      data
    end

    def write(path, data)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |file|
        YAML.dump(data, file)
      end
    end
  end
end
