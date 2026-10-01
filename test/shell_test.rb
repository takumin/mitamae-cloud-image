# frozen_string_literal: true

require_relative 'test_helper'

class ShellTest < Minitest::Test
  Shell = MitamaeCloudImage::Shell

  def test_run_prints_stdout_and_stderr
    result = nil
    out, = capture_io { result = Shell.run('echo out; echo err >&2') }

    assert result
    assert_includes out.lines, "out\n"
    assert_includes out.lines, "err\n"
  end

  def test_run_returns_false_on_failure
    result = nil
    capture_io { result = Shell.run('exit 3') }

    refute result
  end
end
