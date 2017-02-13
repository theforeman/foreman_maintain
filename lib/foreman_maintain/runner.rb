module ForemanMaintain
  # Class responsible for running the scenario
  class Runner
    require 'foreman_maintain/runner/execution'
    def initialize(reporter, scenario)
      @reporter = reporter
      @scenario = scenario
      @executions = []
    end

    def run
      @reporter.before_scenario_starts(@scenario)
      @scenario.steps.each do |step|
        execution = Execution.new(step, @reporter)
        execution.run
        @executions << execution
      end
      @reporter.after_scenario_finishes(@scenario)
    end
  end
end
