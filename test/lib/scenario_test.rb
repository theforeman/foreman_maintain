require 'test_helper'

module ForemanMaintain
  describe Scenario do
    let(:scenario) { Scenarios::WithContext.new(:param => 'value') }
    let(:reporter) { Support::LogReporter.new }
    let(:runner) { Runner.new(reporter, scenario) }

    it 'pass context params to the procedure' do
      runner.run
      reporter.output.must_equal("value\n")
    end
  end
end
