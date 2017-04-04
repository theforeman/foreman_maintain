require 'test_helper'

module ForemanMaintain
  describe Reporter::CLIReporter do
    include CliAssertions

    let :capture do
      StringIO.new
    end

    let :fake_stdin do
      StringIO.new
    end

    let :reporter do
      Reporter::CLIReporter.new(capture, fake_stdin)
    end

    let :scenario do
      Scenarios::PresentUpgrade.new
    end

    def decision_question(description)
      "Continue with step [#{description}]?, [y(yes), n(no), q(quit)]"
    end

    it 'reports human-readmable info about the run' do
      reporter.before_scenario_starts(scenario)

      step = Checks::PresentServiceIsRunning.new
      execution = Runner::Execution.new(step, reporter)

      reporter.before_execution_starts(execution)
      execution.status = :success
      reporter.after_execution_finishes(execution)

      reporter.before_execution_starts(execution)
      execution.status = :fail
      execution.output = 'The service is not running'
      reporter.after_execution_finishes(execution)

      reporter.after_scenario_finishes(scenario)

      assert_equal <<-STR.strip_heredoc, captured_out
        Running present_service upgrade scenario
        --------------------------------------------------------------------------------
        present service run check:                                            [OK]
        --------------------------------------------------------------------------------
        present service run check:                                            [FAIL]
        The service is not running
        --------------------------------------------------------------------------------
      STR
    end

    it 'asks about the next steps' do
      runner_mock = MiniTest::Mock.new
      will_press('y')
      start_step = Procedures::PresentServiceStart.new
      restart_step = Procedures::PresentServiceRestart.new
      runner_mock.expect(:add_step, nil, [start_step])
      reporter.on_next_steps(runner_mock, [start_step])
      assert_equal decision_question('start the present service'), captured_out(false).strip

      will_press('2')
      runner_mock.expect(:add_step, nil, [restart_step])
      reporter.on_next_steps(runner_mock, [start_step, restart_step])
      assert_equal <<-STR.strip_heredoc.strip, captured_out(false).strip
        There are multiple steps to proceed:
        1) start the present service
        2) restart present service
        Select step to continue, [n(next), q(quit)]
      STR

      will_press('q')
      runner_mock.expect(:ask_to_quit, nil)
      reporter.on_next_steps(runner_mock, [start_step, restart_step])
    end

    describe 'skip_to_next' do
      it 'option N/n is to skip the current prompted step' do
        runner_mock = MiniTest::Mock.new
        restart_step = Procedures::PresentServiceRestart.new

        will_press('n')
        runner_mock.expect(:skip_to_next, nil, [restart_step])
        reporter.on_next_steps(runner_mock, [restart_step])

        assert_equal decision_question('restart present service'), captured_out(false).strip
      end
    end

    def will_press(string)
      fake_stdin.rewind
      fake_stdin.puts(string)
      fake_stdin.rewind
    end

    def captured_out(simulate_terminal = true)
      capture.rewind
      # simulate carriage returns to get the output as user would see it
      out = capture.read
      out = simulate_carriage_returns(out) if simulate_terminal
      out = remove_colors(out)
      capture.rewind
      out
    end
  end
end
