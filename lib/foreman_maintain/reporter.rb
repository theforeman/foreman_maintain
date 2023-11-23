module ForemanMaintain
  class Reporter
    class DummySpinner
      def update(_message)
        # do nothing
      end
    end
    require 'foreman_maintain/reporter/cli_reporter'

    DECISION_MAPPER = {
      %w[y yes] => :yes,
      %w[n next no] => :no,
      %w[q quit] => :quit,
    }.freeze

    # Each public method is a hook called by executor at the specific point
    def before_scenario_starts(_scenario, _last_scenario = nil)
    end

    def before_execution_starts(_execution)
    end

    def after_execution_finishes(_execution)
    end

    def after_scenario_finishes(_scenario)
    end

    def on_next_steps(steps, run_strategy = :fail_fast)
      return if steps.empty?

      if steps.size > 1
        multiple_steps_decision(steps, run_strategy)
      else
        single_step_decision(steps.first, run_strategy)
      end
    end

    def with_spinner(_message, &_block)
      yield DummySpinner.new
    end

    def print(_message)
    end

    def puts(_message)
    end

    def ask(_message)
    end

    def assumeyes?
      @assumeyes
    end

    def plaintext?
      @plaintext
    end

    # simple yes/no question, returns :yes, :no or :quit
    # rubocop:disable Metrics/LineLength
    def ask_decision(message, actions_msg: 'y(yes), n(no), q(quit)', assumeyes: assumeyes?, run_strategy: :fail_fast)
      actions_msg = 'y(yes), n(no)' if run_strategy == :fail_slow
      if assumeyes
        print("#{message} (assuming yes)")
        return :yes
      end

      until_valid_decision do
        filter_decision(ask("#{message}, [#{actions_msg}]"))
      end
    end
    # rubocop:enable Metrics/LineLength

    def assumeyes=(assume)
      @assumeyes = !!assume
    end

    def plaintext=(plaintext)
      @plaintext = !!plaintext
    end

    private

    def single_step_decision(step, run_strategy)
      answer = ask_decision("Continue with step [#{step.description}]?", run_strategy: run_strategy)
      if answer == :yes
        step
      else
        answer
      end
    end

    def multiple_steps_decision(steps, run_strategy)
      puts 'There are multiple steps to proceed:'
      steps.each_with_index do |step, index|
        puts "#{index + 1}) #{step.description}"
      end
      ask_to_select('Select step to continue', steps, run_strategy)
    end

    def filter_decision(answer)
      decision = nil
      DECISION_MAPPER.each do |options, decision_label|
        decision = decision_label if options.include?(answer)
      end
      decision
    end

    def ask_to_select(message, steps, run_strategy)
      if assumeyes?
        puts('(assuming first option)')
        return steps.first
      end
      until_valid_decision do
        actions = (run_strategy == :fail_slow) ? 'n(next)' : 'n(next), q(quit)'

        answer = ask("#{message}, [#{actions}]")
        if answer =~ /^\d+$/ && (answer.to_i - 1) < steps.size
          steps[answer.to_i - 1]
        else
          decision = filter_decision(answer)
          if decision == :yes
            steps.first
          else
            decision
          end
        end
      end
    end

    # loop over the block until it returns some non-false value
    def until_valid_decision
      decision = nil
      decision = yield until decision
      decision
    end
  end
end
