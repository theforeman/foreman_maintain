class Support
  class LogReporter < ForemanMaintain::Reporter
    attr_reader :log, :output
    attr_accessor :planned_next_steps_answers

    def initialize
      @log = []
      @output = ''
      @planned_next_steps_answers = []
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

    %w[print puts ask].each do |method|
      define_method(method) do |message|
        log_method(method, message)
        @output << message
        if method != 'print'
          @output << "\n"
        end
      end
    end

    def on_next_steps(steps)
      @log << [__method__.to_s].concat(stringified_args(*steps))
      next_answer = @planned_next_steps_answers.shift
      case next_answer
      when 'y'
        steps.first
      when 'n', nil
        :quit
      when /\d/
        steps[next_answer.to_i - 1]
      else
        raise "Unexpected next answer #{next_answer}"
      end
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
