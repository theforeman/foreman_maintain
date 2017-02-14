require 'test_helper'

module ForemanMaintain
  describe Filter do
    let :detector do
      Detector.new
    end

    let :scenarios do
      detector.available_scenarios
    end

    let :checks do
      detector.available_checks
    end

    it 'allows to filter checks based on metadata and present features' do
      filter = Filter.new(checks, :tags => :basic)
      assert(filter.run.find { |c| c.is_a? Checks::MyTestIsRunning },
             'checks that should be found is missing')
      refute(filter.run.find { |c| c.is_a? Checks::MissingServiceIsRunning },
             'checks that should not be found are present')
    end

    it 'allows to filter scenarios based on metadata and present features' do
      filter = Filter.new(scenarios, :tags => :upgrade)
      assert(filter.run.find { |c| c.is_a? Scenarios::Upgrade1 },
             'scenarios that should be found is missing')
      refute(filter.run.find { |c| c.is_a? Scenarios::Upgrade2 },
             'scenarios that should not be found are present')
    end
  end
end
