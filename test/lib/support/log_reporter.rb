class Support
  class LogReporter < ForemanMaintain::Reporter
    attr_reader :log, :output

    def initialize
      @log = []
      @output = ''
    end

    def log_method(method, *args)
      @log << [method].concat(stringified_args(*args))
    end

    %w[before_scenario_starts before_execution_starts on_execution_update
       after_execution_finishes after_scenario_finishes].each do |method|
      define_method(method) do |*args|
        log_method(method, *args)
      end
    end

    %w(print puts ask).each do |method|
      define_method(method) do |message|
        log_method(method, message)
        @output << message
        if method != 'print'
          @output << "\n"
        end
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
        else
          arg
        end
      end
    end
  end
end
