module ForemanMaintain
  # Class responsible for running the scenario
  class Runner
    require 'foreman_maintain/runner/execution'
    def initialize(reporter, *scenarios)
      @reporter = reporter
      @scenarios = scenarios
      @scenarios_with_dependencies = scenarios_with_dependencies
      @quit = false
    end

    def scenarios_with_dependencies
      @scenarios.map do |scenario|
        scenario.before_scenarios + [scenario]
      end.flatten
    end

    def run
      scenarios_with_dependencies.each do |scenario|
        run_scenario(scenario)
      end
    end

    def run_scenario(scenario)
      @steps_to_run = scenario.steps.dup
      @reporter.before_scenario_starts(scenario)
      while !@quit && !@steps_to_run.empty?
        step = @steps_to_run.shift
        execution = Execution.new(step, @reporter)
        execution.run
        ask_about_offered_steps(step)
      end
      @reporter.after_scenario_finishes(scenario)
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

    def ask_about_offered_steps(step)
      if step.next_steps && !step.next_steps.empty?
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
  end
end
