require 'test_helper'

module ForemanMaintain
  describe Runner do
    let :scenario do
      Scenarios::PresentUpgrade.new
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
                   [['before_scenario_starts', 'present_service upgrade scenario'],
                    ['before_execution_starts', 'present service run check'],
                    ['after_execution_finishes', 'present service run check'],
                    ['after_scenario_finishes', 'present_service upgrade scenario']],
                   'unexpected order of execution')
    end
  end
end
