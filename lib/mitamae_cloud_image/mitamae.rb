# frozen_string_literal: true

require 'etc'
require 'fileutils'
require 'open-uri'

module MitamaeCloudImage
  # Installs the mitamae binary that runs the initialize and finalize phases
  module Mitamae
    VERSION = 'v1.14.1'

    module_function

    def url(version: VERSION, machine: Etc.uname[:machine])
      "https://github.com/itamae-kitchen/mitamae/releases/download/#{version}/mitamae-#{machine}-linux"
    end

    def install(bin, version: VERSION, source: url(version: version), fetch: method(:download))
      FileUtils.mkdir_p(File.dirname(bin))

      File.delete(bin) if File.exist?(bin) and !installed?(bin, version)

      File.binwrite(bin, fetch.call(source)) unless File.exist?(bin)

      FileUtils.chmod(0755, bin) unless FileTest.executable?(bin)
    end

    def installed?(bin, version)
      return false unless FileTest.executable?(bin)

      `#{bin} version`.match?(version)
    rescue StandardError
      false
    end

    def download(url)
      URI.open(url, &:read)
    end
  end
end
