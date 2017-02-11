require 'test_helper'

module ForemanMaintain
  describe Filter do
    include ResetTestState

    let :filter do
      Filter.new(Check, :tags => :basic)
    end

    it 'allows to filter checks based on metadata and present features' do
      assert_includes(filter.run, Checks::MyTestIsRunning,
                      'checks that should be found is missing')
    end
  end
end
