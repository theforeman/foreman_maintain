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
      reporter.planned_next_steps_answers = %w[y n]
      runner.run
      assert_equal([['before_scenario_starts', 'present_service upgrade scenario'],
                    ['before_execution_starts', 'present service run check'],
                    ['after_execution_finishes', 'present service run check'],
                    ['on_next_steps', 'start the present service'],
                    ['before_execution_starts', 'start the present service'],
                    ['after_execution_finishes', 'start the present service'],
                    ['puts', 'Rerunning the check after fix procedure'],
                    ['before_execution_starts', 'present service run check'],
                    ['after_execution_finishes', 'present service run check'],
                    ['on_next_steps', 'start the present service'],
                    ['before_execution_starts', 'service not running check'],
                    ['after_execution_finishes', 'service not running check'],
                    ['on_next_steps', 'stop the running service'],
                    ['before_execution_starts', 'restart present service'],
                    ['after_execution_finishes', 'restart present service'],
                    ['after_scenario_finishes', 'present_service upgrade scenario']],
                   reporter.log,
                   'unexpected order of execution')
    end

    it "assumeyes doesn't cause endless loops" do
      reporter = Support::LogReporter.new(:assumeyes => true)
      runner = Runner.new(reporter, scenario, :assumeyes => true)
      runner.run
      assert_equal([['before_scenario_starts', 'present_service upgrade scenario'],
                    ['before_execution_starts', 'present service run check'],
                    ['after_execution_finishes', 'present service run check'],
                    ['on_next_steps', 'start the present service'],
                    ['before_execution_starts', 'start the present service'],
                    ['after_execution_finishes', 'start the present service'],
                    ['puts', 'Rerunning the check after fix procedure'],
                    ['before_execution_starts', 'present service run check'],
                    ['after_execution_finishes', 'present service run check'],
                    ['puts', 'Check still failing after attempt to fix. Skipping'],
                    ['before_execution_starts', 'service not running check'],
                    ['after_execution_finishes', 'service not running check'],
                    ['on_next_steps', 'stop the running service'],
                    ['before_execution_starts', 'stop the running service'],
                    ['after_execution_finishes', 'stop the running service'],
                    ['puts', 'Rerunning the check after fix procedure'],
                    ['before_execution_starts', 'service not running check'],
                    ['after_execution_finishes', 'service not running check'],
                    ['puts', 'Check still failing after attempt to fix. Skipping'],
                    ['before_execution_starts', 'restart present service'],
                    ['after_execution_finishes', 'restart present service'],
                    ['after_scenario_finishes', 'present_service upgrade scenario']],
                   reporter.log,
                   'unexpected order of execution')
    end

    it 'performs preparation scenarios when preparations steps are necessary' do
      Procedures::Setup.any_instance.stubs(:setup_already? => false)
      reporter.planned_next_steps_answers = %w[y n]
      runner.run
      # rubocop:disable Style/WordArray
      assert_equal(
        [['before_scenario_starts', 'preparation steps required to run the next scenarios'],
         ['before_execution_starts', 'setup'],
         ['after_execution_finishes', 'setup'],
         ['after_scenario_finishes', 'preparation steps required to run the next scenarios']],
        reporter.log.first(4),
        'unexpected order of execution'
      )
    end

    describe 'scnario confirmation in before_scenario_starts' do
      let(:success_scenario) do
        Scenarios::Dummy::Success.new
      end

      let(:warn_and_fail_scenario) do
        Scenarios::Dummy::WarnAndFail.new
      end

      it 'does not continue when the reporter does not confirm the scenario' do
        runner = Runner.new(reporter, [success_scenario])
        reporter.confirm_scenario = :no
        runner.run
        assert_equal([
                       ['before_scenario_starts', 'Scenarios::Dummy::Success']
                     ], reporter.log, 'unexpected execution')
      end
    end

    describe 'run_strategy' do
      let(:fail_fast_scenario) do
        Scenarios::Dummy::FailFast.new
      end

      let(:fail_slow_scenario) do
        Scenarios::Dummy::FailSlow.new
      end

      specify 'fail_fast scenario gets stopped right on first failure' do
        runner = Runner.new(reporter, [fail_fast_scenario])
        runner.run
        assert_equal([
                       ['before_scenario_starts', 'Scenarios::Dummy::FailFast'],
                       ['before_execution_starts', 'check that ends up with fail'],
                       ['after_execution_finishes', 'check that ends up with fail'],
                       ['after_scenario_finishes', 'Scenarios::Dummy::FailFast']
                     ], reporter.log, 'unexpected execution')
      end

      specify 'fail_slow scenario runs the next steps despite the failures' do
        runner = Runner.new(reporter, [fail_slow_scenario])
        runner.run
        assert_equal([
                       ['before_scenario_starts', 'Scenarios::Dummy::FailSlow'],
                       ['before_execution_starts', 'check that ends up with fail'],
                       ['after_execution_finishes', 'check that ends up with fail'],
                       ['before_execution_starts', 'check that ends up with success'],
                       ['after_execution_finishes', 'check that ends up with success'],
                       ['after_scenario_finishes', 'Scenarios::Dummy::FailSlow']
                     ], reporter.log, 'unexpected execution')
      end
    end
  end
end
