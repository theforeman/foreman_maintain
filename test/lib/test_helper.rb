require File.expand_path('../test_helper', File.dirname(__FILE__))

class TestHelper
  class << self
    attr_accessor :use_present_service_2, :present_service_is_running, :migrations_fail_at,
                  :service_is_stopped

    def reset
      self.use_present_service_2 = false
      self.present_service_is_running = false
      self.service_is_stopped = false
      self.migrations_fail_at = nil
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

TEST_DIR = File.dirname(__FILE__)
CONFIG_FILE = File.join(TEST_DIR, 'config/foreman_maintain.yml.test').freeze

ForemanMaintain.setup
