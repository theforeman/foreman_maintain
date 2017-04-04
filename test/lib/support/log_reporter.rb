class Support
  class LogReporter < ForemanMaintain::Reporter
    attr_reader :log

    def initialize
      @log = []
    end

    %w[before_scenario_starts before_execution_starts on_execution_update
       after_execution_finishes after_scenario_finishes].each do |method|
      define_method(method) do |*args|
        @log << [method].concat(stringified_args(*args))
      end
    end

    def on_next_steps(runner, steps)
      runner.add_step(steps.first)
      @log << [__method__.to_s].concat(stringified_args(*steps))
    end

    def stringified_args(*args)
      args.map do |arg|
        case arg
        when ForemanMaintain::Scenario, ForemanMaintain::Executable
          arg.description
        when ForemanMaintain::Runner::Execution
          arg.name
        end
      end
    end
  end
end
