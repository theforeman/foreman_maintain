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
  rescue SystemExit # rubocop:disable Lint/HandleExceptions
    # don't accept system exit from running a command
  end

  def simulate_carriage_returns(output)
    output.gsub(/^.*\r/, '')
  end

  def remove_colors(output)
    output.gsub(/\e.*?m/, '')
  end
end

module UnitTestHelper
  def described_class
    # Memoization doesn't work on class methods need to think how to cache it per test
    # One option is to use 'let' per test file
    @described_class ||=
      begin
        const_name = self.class.name
        return described_class_ruby_187(const_name) if RUBY_VERSION >= '1.8.7'
        Object.const_get(const_name)
      end
  end

  def described_class_ruby_187(const_name)
    const_name.split('::').inject(Object) do |mod, class_name|
      mod.const_get(class_name)
    end
  end
end

include UnitTestHelper
