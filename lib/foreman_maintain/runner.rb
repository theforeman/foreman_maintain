module ForemanMaintain
  # Class responsible for running the scenario
  class Runner
    require 'foreman_maintain/runner/execution'
    def initialize(reporter, scenario)
      @reporter = reporter
      @scenario = scenario
      @executions = []
      @steps_to_run = @scenario.steps.dup
      @quit = false
    end

    def run
      @reporter.before_scenario_starts(@scenario)
      while !@quit && !@steps_to_run.empty?
        step = @steps_to_run.shift
        execution = Execution.new(step, @reporter)
        execution.run
        @executions << execution
        ask_about_offered_steps(step.next_steps)
      end
      @reporter.after_scenario_finishes(@scenario)
    end

    def ask_to_quit(_step = nil)
      @quit = true
    end

    def add_step(step)
      @steps_to_run.unshift(step)
    end

    private

    def ask_about_offered_steps(steps)
      if steps && !steps.empty?
        steps = steps.map(&:ensure_instance)
        decision = @reporter.on_next_steps(steps)
        case decision
        when :quit
          ask_to_quit
        when Executable
          add_step(decision)
        else
          raise "Unexpected decision #{decision}" unless decision == :no
        end
      end
    end
  end
end
