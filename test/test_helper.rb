require 'foreman_maintain'
require 'minitest/spec'
require 'minitest/autorun'
require 'mocha/mini_test'

module CliAssertions
  def assert_cmd(expected_output, args = [])
    output, _err = run_cmd(args)
    assert_equal expected_output, remove_colors(simulate_carriage_returns(output))
  end

  def run_cmd(args = [])
    capture_io do
      ForemanMaintain::Cli::MainCommand.run('foreman-maintain', command + args)
    end
  end

  def simulate_carriage_returns(output)
    output.gsub(/^.*\r/, '')
  end

  def remove_colors(output)
    output.gsub(/\e.*?m/, '')
  end
end
