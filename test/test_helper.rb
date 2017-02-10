class TestHelper
  class << self
    attr_accessor :use_my_test_feature_2
  end
end

require 'foreman_maintain'
require 'minitest/spec'
require 'minitest/autorun'

TEST_DIR = File.dirname(__FILE__)

ForemanMaintain.setup(
  :definitions_dirs => [File.join(TEST_DIR, 'support', 'definitions'),
                        File.join(TEST_DIR, 'support', 'additional_definitions')],
  :log_level => Logger::UNKNOWN
)
