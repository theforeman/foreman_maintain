require 'test_helper'

module ForemanMaintain
  describe Reporter::CLIReporter do
    let :capture do
      StringIO.new
    end

    let :reporter do
      Reporter::CLIReporter.new(capture)
    end

    let :scenario do
      Scenarios::Upgrade1.new
    end

    it 'reports human-readmable info about the run' do
      reporter.before_scenario_starts(scenario)

      step = Checks::MyTestIsRunning.new
      execution = Runner::Execution.new(step, reporter)

      reporter.before_execution_starts(execution)
      execution.status = :success
      reporter.after_execution_finishes(execution)

      reporter.before_execution_starts(execution)
      execution.status = :fail
      execution.output = 'The service is not running'
      reporter.after_execution_finishes(execution)

      reporter.after_scenario_finishes(scenario)

      assert_equal <<STR, captured_out
Running my_test upgrade scenario
--------------------------------------------------------------------------------
| my test is running check:                                         [OK]       |
--------------------------------------------------------------------------------
| my test is running check:                                         [FAIL]     |
| The service is not running                                                   |
--------------------------------------------------------------------------------
STR
    end

    def captured_out
      capture.rewind
      # simulate carriage returns to get the output as user would see it
      out = capture.read.gsub(/^.*\r/, '')
      # remove coloring
      out.gsub!(/\e.*?m/, '')
      out
    end
  end
end
