require 'foreman_maintain'
require 'minitest/spec'
require 'minitest/autorun'

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

TEST_DIR = File.dirname(__FILE__)

ForemanMaintain.setup(
  :definitions_dirs => [File.join(TEST_DIR, 'support', 'definitions'),
                        File.join(TEST_DIR, 'support', 'additional_definitions')],
  :log_level => Logger::UNKNOWN
)
