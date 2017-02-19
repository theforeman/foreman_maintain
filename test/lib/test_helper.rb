require 'foreman_maintain'
require 'minitest/spec'
require 'minitest/autorun'
require 'mocha/mini_test'

require 'support/log_reporter'

class TestHelper
  class << self
    attr_accessor :use_present_service_2, :present_service_is_running

    def reset
      self.use_present_service_2 = false
      self.present_service_is_running = false
    end
  end
end

module ResetTestState
  def self.included(klass)
    klass.before do
      TestHelper.reset
    end
  end
end

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

TEST_DIR = File.dirname(__FILE__)

ForemanMaintain.setup(
  :definitions_dirs => [File.join(TEST_DIR, 'support', 'definitions'),
                        File.join(TEST_DIR, 'support', 'additional_definitions')],
  :log_level => Logger::UNKNOWN
)
