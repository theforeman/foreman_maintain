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
      assert_equal([['before_scenario_starts', 'present_service upgrade scenario'],
                    ['before_execution_starts', 'present service run check'],
                    ['after_execution_finishes', 'present service run check'],
                    ['on_next_steps', 'start the present service'],
                    ['before_execution_starts', 'start the present service'],
                    ['after_execution_finishes', 'start the present service'],
                    ['before_execution_starts', 'restart present service'],
                    ['after_execution_finishes', 'restart present service'],
                    ['after_scenario_finishes', 'present_service upgrade scenario']],
                   reporter.log,
                   'unexpected order of execution')
    end
  end
end
