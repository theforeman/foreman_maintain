require 'test_helper'

module ForemanMaintain
  describe Runner do
    let :scenario do
      Scenarios::PresentUpgrade::PreUpgradeChecks.new
    end

    let :reporter do
      Support::LogReporter.new
    end

    let :runner do
      Runner.new(reporter, scenario)
    end

    let :success_scenario do
      Scenarios::Dummy::Success.new
    end

    let :warn_scenario do
      Scenarios::Dummy::Warn.new
    end

    let :failed_scenario do
      Scenarios::Dummy::Fail.new
    end

    let :warn_and_fail_scenario do
      Scenarios::Dummy::WarnAndFail.new
    end

    it 'performs all steps in the scenario' do
      reporter.planned_next_steps_answers = %w[y n]
      runner.run
      assert_equal([['before_scenario_starts', :present_upgrade_pre_upgrade_checks],
                    ['before_execution_starts', :present_service_is_running],
                    ['after_execution_finishes', :present_service_is_running],
                    ['on_next_steps', :present_service_start],
                    ['before_execution_starts', :present_service_start],
                    ['after_execution_finishes', :present_service_start],
                    ['puts', 'Rerunning the check after fix procedure'],
                    ['before_execution_starts', :present_service_is_running],
                    ['after_execution_finishes', :present_service_is_running],
                    ['on_next_steps', :present_service_start],
                    ['before_execution_starts', :service_is_stopped],
                    ['after_execution_finishes', :service_is_stopped],
                    ['on_next_steps', :stop_service],
                    ['before_execution_starts', :present_service_restart],
                    ['after_execution_finishes', :present_service_restart],
                    ['after_scenario_finishes', :present_upgrade_pre_upgrade_checks]],
                   reporter.log,
                   'unexpected order of execution')
    end

    it "assumeyes doesn't cause endless loops" do
      reporter = Support::LogReporter.new(:assumeyes => true)
      runner = Runner.new(reporter, scenario, :assumeyes => true)
      runner.run
      assert_equal([['before_scenario_starts', :present_upgrade_pre_upgrade_checks],
                    ['before_execution_starts', :present_service_is_running],
                    ['after_execution_finishes', :present_service_is_running],
                    ['on_next_steps', :present_service_start],
                    ['before_execution_starts', :present_service_start],
                    ['after_execution_finishes', :present_service_start],
                    ['puts', 'Rerunning the check after fix procedure'],
                    ['before_execution_starts', :present_service_is_running],
                    ['after_execution_finishes', :present_service_is_running],
                    ['puts', 'Check still failing after attempt to fix. Skipping'],
                    ['before_execution_starts', :service_is_stopped],
                    ['after_execution_finishes', :service_is_stopped],
                    ['on_next_steps', :stop_service],
                    ['before_execution_starts', :stop_service],
                    ['after_execution_finishes', :stop_service],
                    ['puts', 'Rerunning the check after fix procedure'],
                    ['before_execution_starts', :service_is_stopped],
                    ['after_execution_finishes', :service_is_stopped],
                    ['puts', 'Check still failing after attempt to fix. Skipping'],
                    ['before_execution_starts', :present_service_restart],
                    ['after_execution_finishes', :present_service_restart],
                    ['after_scenario_finishes', :present_upgrade_pre_upgrade_checks]],
                   reporter.log,
                   'unexpected order of execution')
    end

    it 'performs preparation scenarios when preparations steps are necessary' do
      Procedures::Setup.any_instance.stubs(:setup_already? => false)
      reporter.planned_next_steps_answers = %w[y n]
      runner.run
      assert_equal(
        [['before_scenario_starts', :foreman_maintain_scenario_preparation_scenario],
         ['before_execution_starts', :setup],
         ['after_execution_finishes', :setup],
         ['after_scenario_finishes', :foreman_maintain_scenario_preparation_scenario]],
        reporter.log.first(4),
        'unexpected order of execution'
      )
    end

    describe 'scenario confirmation in before_scenario_starts' do
      it 'does not continue when the reporter does not confirm the scenario' do
        runner = Runner.new(reporter, [warn_scenario, success_scenario])
        runner.run
        reporter.log.last.
          must_equal(['ask', 'Continue with [Scenarios::Dummy::Success], [y(yes), n(no), q(quit)]'])
      end
    end

    describe 'skipping run steps' do
      let(:scenario) do
        Scenarios::Dummy::RunOnce.new
      end

      it 'skips the step marked as run_once if already run' do
        runner = Runner.new(reporter, [scenario])
        runner.run

        new_reporter = Support::LogReporter.new
        new_runner = Runner.new(new_reporter, [scenario])
        new_runner.run
        scenario.steps.map { |x| x.execution.status }.must_equal([:success, :fail])
        reporter.executions.must_equal [['Procedures::RunOnce', :success],
                                        ['Check that ends up with fail', :fail]]
        new_reporter.executions.must_equal [['Procedures::RunOnce', :already_run],
                                            ['Check that ends up with fail', :fail]]
      end

      it 'runs the step marked as run_once if already run but called with --force' do
        runner = Runner.new(reporter, [scenario])
        runner.run

        new_reporter = Support::LogReporter.new
        new_runner = Runner.new(new_reporter, [scenario], :force => true)
        new_runner.run
        scenario.steps.map { |x| x.execution.status }.must_equal([:success, :fail])
        reporter.executions.must_equal [['Procedures::RunOnce', :success],
                                        ['Check that ends up with fail', :fail]]
        new_reporter.executions.must_equal [['Procedures::RunOnce', :success],
                                            ['Check that ends up with fail', :fail]]
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
                       ['before_scenario_starts', :dummy_fail_fast],
                       ['before_execution_starts', :dummy_check_fail],
                       ['after_execution_finishes', :dummy_check_fail],
                       ['after_scenario_finishes', :dummy_fail_fast]
                     ], reporter.log, 'unexpected execution')
      end

      specify 'fail_slow scenario runs the next steps despite the failures' do
        runner = Runner.new(reporter, [fail_slow_scenario])
        runner.run
        assert_equal([
                       ['before_scenario_starts', :dummy_fail_slow],
                       ['before_execution_starts', :dummy_check_fail],
                       ['after_execution_finishes', :dummy_check_fail],
                       ['before_execution_starts', :dummy_check_success],
                       ['after_execution_finishes', :dummy_check_success],
                       ['after_scenario_finishes', :dummy_fail_slow]
                     ], reporter.log, 'unexpected execution')
      end
    end

    describe '#exit_code' do
      it 'sets to 1 if scenario failed' do
        runner = Runner.new(reporter, [failed_scenario])
        runner.run
        assert_equal 1, runner.exit_code
      end

      it 'is default(0) if scenario passed' do
        runner = Runner.new(reporter, [success_scenario])
        runner.run
        assert_equal 0, runner.exit_code
      end

      it 'is 78 if scenario has warnings' do
        runner = Runner.new(reporter, [warn_scenario])
        runner.run
        assert_equal 78, runner.exit_code
      end
    end
  end
end
