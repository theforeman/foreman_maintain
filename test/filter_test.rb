require 'test_helper'

module ForemanMaintain
  describe Filter do
    it 'allows to filter checks based on metadata and present features' do
      filter = Filter.new(Check, :tags => :basic)
      assert_includes(filter.run, Checks::MyTestIsRunning,
                      'checks that should be found is missing')
      refute_includes(filter.run, Checks::MissingServiceIsRunning,
                      'checks that should not be found are present')
    end

    it 'allows to filter scenarios based on metadata and present features' do
      filter = Filter.new(Scenario, :tags => :upgrade)
      assert_includes(filter.run, Scenarios::Upgrade1,
                      'scenarios that should be found is missing')
      refute_includes(filter.run, Scenarios::Upgrade2,
                      'scenarios that should not be found are present')
    end
  end
end
