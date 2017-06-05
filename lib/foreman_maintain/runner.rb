module ForemanMaintain
  # Class responsible for running the scenario
  class Runner
    attr_reader :reporter

    require 'foreman_maintain/runner/execution'
    require 'foreman_maintain/runner/stored_execution'
    def initialize(reporter, scenarios, options = {})
      options.validate_options!(:assumeyes, :whitelist)
      @assumeyes = options.fetch(:assumeyes, false)
      @whitelist = options.fetch(:whitelist, [])
      @reporter = reporter
      @scenarios = Array(scenarios)
      @quit = false
      @last_scenario = nil
    end

    def quit?
      @quit
    end

    def assumeyes?
      @assumeyes
    end

    def run
      @scenarios.each do |scenario|
        run_scenario(scenario)
        break if @quit
      end
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def run_scenario(scenario)
      return if scenario.steps.empty?
      raise 'The runner is already in quit state' if @quit
      scenario.before_scenarios.flatten.each { |before_scenario| run_scenario(before_scenario) }
      return if quit? # the before scenarios caused the stop of the execution
      confirm_scenario(scenario)
      return if quit?
      @reporter.before_scenario_starts(scenario)
      run_steps(scenario, scenario.steps)
      @reporter.after_scenario_finishes(scenario)
    ensure
      @last_scenario = scenario unless scenario.steps.empty?
    end

    def whitelisted_step?(step)
      @whitelist.include?(step.label_dashed.to_s)
    end

    def confirm_scenario(scenario)
      return unless @last_scenario
      decision = if @last_scenario.steps_with_error(:whitelisted => false).any?
                   :quit
                 elsif @last_scenario.steps_with_warning(:whitelisted => false).any?
                   reporter.ask_decision("Continue with [#{scenario.description}]")
                 end

      ask_to_quit if [:quit, :no].include?(decision)
      decision
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

    def run_steps(scenario, steps)
      @steps_to_run = ForemanMaintain::DependencyGraph.sort(steps)
      while !@quit && !@steps_to_run.empty?
        step = @steps_to_run.shift
        @reporter.puts('Rerunning the check after fix procedure') if rerun_check?(step)
        execution = Execution.new(step, @reporter, :whitelisted => whitelisted_step?(step))
        execution.run
        post_step_decisions(scenario, execution)
      end
    end

    def post_step_decisions(scenario, execution)
      step = execution.step
      next_steps_decision = ask_about_offered_steps(step)
      if next_steps_decision != :yes &&
         execution.fail? && !execution.whitelisted? &&
         scenario.run_strategy == :fail_fast
        ask_to_quit
      end
    end

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
          :yes
        end
      end
    end

    def rerun_check?(step)
      @last_decision_step == step
    end
  end
end
