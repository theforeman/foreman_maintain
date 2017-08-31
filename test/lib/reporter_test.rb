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

    let(:warn_scenario) do
      Scenarios::Dummy::Warn.new
    end

    let(:fail_scenario) do
      Scenarios::Dummy::Fail.new
    end

    let(:fail_multiple_scenario) do
      Scenarios::Dummy::FailMultiple.new
    end

    let(:warn_and_fail_scenario) do
      Scenarios::Dummy::WarnAndFail.new
    end

    def decision_question(description)
      "Continue with step [#{description}]?, [y(yes), n(no), q(quit)]"
    end

    it 'reports human-readable info about the run' do
      reporter.before_scenario_starts(fail_scenario)
      run_scenario(fail_scenario)

      assert_equal <<-STR.strip_heredoc, captured_out
        Running Scenarios::Dummy::Fail
        ================================================================================
        Check that ends up with fail:                                         [FAIL]
        this check is always causing failure
        --------------------------------------------------------------------------------
        Check that ends up with success:                                      [OK]
        --------------------------------------------------------------------------------
      STR
    end

    it 'asks about the next steps' do
      will_press('y')
      start_step = Procedures::PresentServiceStart.new
      restart_step = Procedures::PresentServiceRestart.new
      reporter.on_next_steps([start_step])
      assert_equal decision_question('Start the present service'), captured_out(false).strip

      will_press('2')
      assert_equal restart_step, reporter.on_next_steps([start_step, restart_step])
      assert_equal <<-STR.strip_heredoc.strip, captured_out(false).strip
        There are multiple steps to proceed:
        1) Start the present service
        2) Restart present service
        Select step to continue, [n(next), q(quit)]
      STR

      will_press('q')
      assert_equal :quit, reporter.on_next_steps([start_step, restart_step])
    end

    it 'informs the user about failures of the last scenario' do
      run_scenario(fail_multiple_scenario)
      reporter.after_scenario_finishes(fail_multiple_scenario)
      assert_equal <<-MESSAGE.strip_heredoc.strip, captured_out(false).strip
      Check that ends up with fail:                                         [FAIL]
      this check is always causing failure
      --------------------------------------------------------------------------------
      Check that ends up with fail:                                         [FAIL]
      this check is always causing failure
      --------------------------------------------------------------------------------
      Check that ends up with success:                                      [OK]
      --------------------------------------------------------------------------------
      Scenario [Scenarios::Dummy::FailMultiple] failed.

      The following steps ended up in failing state:

        [dummy-check-fail]
        [dummy-check-fail2]

      Resolve the failed steps and rerun
      the command. In case the failures are false positives,
      use --whitelist=\"dummy-check-fail,dummy-check-fail2\"
      MESSAGE
    end

    it 'informs the user about warnings of the last scenario' do
      run_scenario(warn_scenario)
      reporter.after_scenario_finishes(warn_scenario)
      assert_equal <<-MESSAGE.strip_heredoc.strip, captured_out(false).strip
        Check that ends up with warning:                                      [WARNING]
        this check is always causing warnings
        --------------------------------------------------------------------------------
        Check that ends up with success:                                      [OK]
        --------------------------------------------------------------------------------
        Scenario [Scenarios::Dummy::Warn] failed.

        The following steps ended up in warning state:

          [dummy-check-warn]

        The steps in warning state itself might not mean there is an error,
        but it should be reviews to ensure the behavior is expected
      MESSAGE
    end

    it 'informs the user about warnings and failures of the last scenario' do
      run_scenario(warn_and_fail_scenario)
      reporter.after_scenario_finishes(warn_and_fail_scenario)
      assert_equal <<-MESSAGE.strip_heredoc.strip, captured_out(false).strip
        Check that ends up with warning:                                      [WARNING]
        this check is always causing warnings
        --------------------------------------------------------------------------------
        Check that ends up with fail:                                         [FAIL]
        this check is always causing failure
        --------------------------------------------------------------------------------
        Check that ends up with success:                                      [OK]
        --------------------------------------------------------------------------------
        Scenario [Scenarios::Dummy::WarnAndFail] failed.

        The following steps ended up in failing state:

          [dummy-check-fail]

        The following steps ended up in warning state:

          [dummy-check-warn]

        Resolve the failed steps and rerun
        the command. In case the failures are false positives,
        use --whitelist=\"dummy-check-fail\"

        The steps in warning state itself might not mean there is an error,
        but it should be reviews to ensure the behavior is expected
      MESSAGE
    end

    it 'ignores whitelisted warnings and failures of the last scenario' do
      run_scenario(warn_and_fail_scenario, :whitelisted => true)
      reporter.after_scenario_finishes(warn_and_fail_scenario)
      assert_equal <<-MESSAGE.strip_heredoc.strip, captured_out(false).strip
        Check that ends up with warning:                                      [WARNING]
        this check is always causing warnings
        --------------------------------------------------------------------------------
        Check that ends up with fail:                                         [FAIL]
        this check is always causing failure
        --------------------------------------------------------------------------------
        Check that ends up with success:                                      [OK]
        --------------------------------------------------------------------------------
      MESSAGE
    end

    describe 'assumeyes' do
      let(:reporter) do
        Reporter::CLIReporter.new(capture, fake_stdin, :assumeyes => true)
      end

      it 'answers yes when assumeyes is active' do
        start_step = Procedures::PresentServiceStart.new
        reporter.on_next_steps([start_step])
        assert_match 'Start the present service', captured_out(false).strip
        assert_match 'assuming yes', captured_out(false).strip
      end

      it 'chooses the first option when multiple options are present' do
        start_step = Procedures::PresentServiceStart.new
        restart_step = Procedures::PresentServiceRestart.new
        assert_equal start_step, reporter.on_next_steps([start_step, restart_step])
        assert_equal <<-STR.strip_heredoc.strip, captured_out(false).strip
        There are multiple steps to proceed:
        1) Start the present service
        2) Restart present service
        (assuming first option)
        STR
      end
    end

    describe 'skip_to_next' do
      it 'option N/n is to skip the current prompted step' do
        restart_step = Procedures::PresentServiceRestart.new

        will_press('n')
        assert_equal :no, reporter.on_next_steps([restart_step])
        assert_equal decision_question('Restart present service'), captured_out(false).strip
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

    def run_scenario(scenario, options = {})
      scenario.steps.each do |step|
        ForemanMaintain::Runner::Execution.new(step, reporter, options).tap(&:run)
      end
    end
  end
end
