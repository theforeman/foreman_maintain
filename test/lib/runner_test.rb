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

    describe 'skip_to_next' do
      let(:scenario) { Scenarios::Deploy.new }
      let(:runner) { Runner.new(reporter, scenario) }
      let(:step) { Procedures::DeleteArticles::OneYearOld.new }

      it 'should mock a skip class' do
        mocked_class = MiniTest::Mock.new
        runner.stubs(:mock_skip_class).with(step).returns([mocked_class])

        runner.skip_to_next(step)
      end

      it 'executes next_steps(if any)' do
        scenario.steps.pop
        steps_to_run = runner.skip_to_next(step)

        assert_equal(1, steps_to_run.count)
      end

      it 'does not adds next_steps if raises error' do
        scenario.steps.pop
        current_step = runner.skip_to_next(step).pop
        steps_to_run = runner.skip_to_next(current_step.new)

        refute(steps_to_run)
      end
    end
  end
end
