require 'test_helper'

module ForemanMaintain
  describe Runner do
    let :scenario do
      Scenarios::Upgrade1.new
    end

    let :reporter do
      Support::LogReporter.new
    end

    let :runner do
      Runner.new(reporter, scenario)
    end

    it 'performs all steps in the scenario' do
      runner.run
      assert_equal(reporter.log,
                   [['before_scenario_starts', 'my_test upgrade scenario'],
                    ['before_execution_starts', 'my test is running check'],
                    ['after_execution_finishes', 'my test is running check'],
                    ['after_scenario_finishes', 'my_test upgrade scenario']],
                   'unexpected order of execution')
    end
  end
end
