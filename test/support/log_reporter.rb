class Support
  class LogReporter < ForemanMaintain::Reporter
    attr_reader :log

    def initialize
      @log = []
    end

    %w(before_scenario_starts before_execution_starts on_execution_update
       after_execution_finishes after_scenario_finishes).each do |method|
      define_method(method) do |*args|
        stringified_args = args.map do |arg|
          case arg
          when ForemanMaintain::Scenario
            arg.description
          when ForemanMaintain::Runner::Execution
            arg.name
          end
        end
        @log << [method].concat(stringified_args)
      end
    end
  end
end
