# frozen_string_literal: true

require_relative 'test_helper'

class MitamaeTest < Minitest::Test
  Mitamae = MitamaeCloudImage::Mitamae

  # A stand-in for the mitamae binary that reports the given version
  def fake_mitamae(version)
    "#!/bin/sh\necho 'mitamae #{version}'\n"
  end

  def fetcher(body)
    calls = []
    fetch = lambda do |url|
      calls << url
      body
    end
    [fetch, calls]
  end

  def test_url
    assert_equal(
      'https://github.com/itamae-kitchen/mitamae/releases/download/v1.14.1/mitamae-aarch64-linux',
      Mitamae.url(version: 'v1.14.1', machine: 'aarch64'),
    )
  end

  def test_install_downloads_a_missing_binary
    Dir.mktmpdir do |dir|
      bin = File.join(dir, '.bin', 'mitamae')
      fetch, calls = fetcher(fake_mitamae('v1.14.1'))

      Mitamae.install(bin, version: 'v1.14.1', source: 'https://example.com/mitamae', fetch: fetch)

      assert_equal ['https://example.com/mitamae'], calls
      assert_equal fake_mitamae('v1.14.1'), File.binread(bin)
      assert FileTest.executable?(bin)
    end
  end

  def test_install_keeps_the_binary_of_the_same_version
    Dir.mktmpdir do |dir|
      bin = File.join(dir, 'mitamae')
      File.write(bin, fake_mitamae('v1.14.1'))
      File.chmod(0755, bin)
      fetch, calls = fetcher('new')

      Mitamae.install(bin, version: 'v1.14.1', fetch: fetch)

      assert_empty calls
      assert_equal fake_mitamae('v1.14.1'), File.read(bin)
    end
  end

  def test_install_replaces_the_binary_of_another_version
    Dir.mktmpdir do |dir|
      bin = File.join(dir, 'mitamae')
      File.write(bin, fake_mitamae('v1.13.0'))
      File.chmod(0755, bin)
      fetch, calls = fetcher(fake_mitamae('v1.14.1'))

      Mitamae.install(bin, version: 'v1.14.1', fetch: fetch)

      assert_equal 1, calls.size
      assert_equal fake_mitamae('v1.14.1'), File.read(bin)
    end
  end

  def test_install_replaces_a_binary_that_is_not_executable
    Dir.mktmpdir do |dir|
      bin = File.join(dir, 'mitamae')
      File.write(bin, fake_mitamae('v1.14.1'))
      File.chmod(0644, bin)
      fetch, calls = fetcher(fake_mitamae('v1.14.1'))

      Mitamae.install(bin, version: 'v1.14.1', fetch: fetch)

      assert_equal 1, calls.size
      assert FileTest.executable?(bin)
    end
  end
end
