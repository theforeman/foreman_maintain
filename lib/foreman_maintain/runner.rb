module ForemanMaintain
  # Class responsible for running the scenario
  class Runner
    require 'foreman_maintain/runner/execution'
    def initialize(reporter, scenarios, options = {})
      options.validate_options!(:assumeyes)
      @assumeyes = options.fetch(:assumeyes, false)
      @reporter = reporter
      @scenarios = Array(scenarios)
      @scenarios_with_dependencies = scenarios_with_dependencies
      @quit = false
    end

    def assumeyes?
      @assumeyes
    end

    def scenarios_with_dependencies
      @scenarios.map do |scenario|
        scenario.before_scenarios + [scenario]
      end.flatten
    end

    def run
      @last_scenario = nil
      scenarios_with_dependencies.each do |scenario|
        next if scenario.steps.empty?
        run_scenario(scenario)
        @last_scenario = scenario
      end
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def run_scenario(scenario)
      @steps_to_run = ForemanMaintain::DependencyGraph.sort(@steps_to_run)
      return unless confirm_scenario(scenario)
      while !@quit && !@steps_to_run.empty?
        step = @steps_to_run.shift
        @reporter.puts('Rerunning the check after fix procedure') if rerun_check?(step)
        execution = Execution.new(step, @reporter)
        execution.run
        ask_about_offered_steps(step)
      end
      @reporter.after_scenario_finishes(scenario)
    end

    def confirm_scenario(scenario)
      decision = @reporter.before_scenario_starts(scenario, @last_scenario)
      case decision
      when :yes
        true
      when :quit, :no
        false
      else
        raise "Unexpected decision #{decision}"
      end
    end

    def ask_to_quit(_step = nil)
      @quit = true
    end

    def add_steps(*steps)
      # we we add the steps at the beginning, but still keeping the
      # order of steps passed in the arguments
      steps.reverse.each do |step|
        @steps_to_run.unshift(step)
      end
    end

    private

    # rubocop:disable Metrics/CyclomaticComplexity
    def ask_about_offered_steps(step)
      if assumeyes? && rerun_check?(step)
        @reporter.puts 'Check still failing after attempt to fix. Skipping'
        return :no
      end
      if step.next_steps && !step.next_steps.empty?
        @last_decision_step = step
        steps = step.next_steps.map(&:ensure_instance)
        decision = @reporter.on_next_steps(steps)
        case decision
        when :quit
          ask_to_quit
        when Executable
          chosen_steps = [decision]
          chosen_steps << step if step.is_a?(Check)
          add_steps(*chosen_steps)
        end
      end
    end

    def rerun_check?(step)
      @last_decision_step == step
    end
  end
end
