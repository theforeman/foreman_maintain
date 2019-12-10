require 'foreman_maintain'
require 'minitest/spec'
require 'minitest/autorun'
require 'mocha/minitest'
require 'stringio'
require File.dirname(__FILE__) + '/support/minitest_spec_context'
require File.expand_path('../lib/support/log_reporter', __FILE__)

module CliAssertions
  def assert_cmd(expected_output, args = [], ignore_whitespace: false)
    output = run_cmd(args)
    if ignore_whitespace
      expected_output = expected_output.gsub(/\s+/, ' ')
      output = output.gsub(/\s+/, ' ')
    end
    assert_equal expected_output, remove_colors(simulate_carriage_returns(output))
  end

  def capture_io_with_stderr
    orig_stdout = $stdout
    orig_stderr = $stderr
    captured_output = StringIO.new
    $stdout = captured_output
    $stderr = captured_output

    yield

    return captured_output.string
  ensure
    $stdout = orig_stdout
    $stderr = orig_stderr
  end

  def run_cmd(args = [])
    capture_io_with_stderr do
      begin
        ForemanMaintain::Cli::MainCommand.run('foreman-maintain', command + args)
      rescue SystemExit # rubocop:disable Lint/HandleExceptions
        # don't accept system exit from running a command
      end
    end
  end

  def simulate_carriage_returns(output)
    output.gsub(/^.*\r/, '')
  end

  def remove_colors(output)
    output.gsub(/\e.*?m/, '')
  end
end

class FakePackageManager < ForemanMaintain::PackageManager::Base
  def initialize
    @packages = []
  end

  def mock_packages(packages)
    @packages = [packages].flatten(1)
  end

  def installed?(packages)
    [packages].flatten(1).all? { |p| @packages.include?(p) }
  end

  def find_installed_package(name)
    @packages.find { |package| package =~ /^#{name}/ }
  end
end

module PackageManagerTestHelper
  class << self
    def mock_package_manager(manager = FakePackageManager.new)
      ForemanMaintain.stubs(:package_manager).returns(manager)
    end

    def assume_package_exist(packages)
      packages = [packages].flatten(1)
      manager = FakePackageManager.new
      manager.mock_packages(packages)
      mock_package_manager(manager)
    end
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
