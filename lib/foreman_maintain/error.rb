module ForemanMaintain
  module Error
    class Fail < StandardError
    end

    class Warn < StandardError
    end

    class Skip < StandardError
    end

    class Abort < StandardError
    end

    class MultipleBeforeDetected < StandardError
      def initialize(step_labels)
        @step_labels = step_labels
      end

      def message
        "multiple metadata detected instead of 1. \n before [#{@step_labels.join(', ')}]\n"
      end
    end

    class ExecutionError < StandardError
      attr_reader :command, :input, :output, :exit_status

      def initialize(command, exit_status, input, output)
        @command = command
        @exit_status = exit_status
        @input = input
        @output = output
        super(generate_message)
      end

      def generate_message
        ret = "Failed executing #{command}, exit status #{exit_status}"
        ret << "with input '#{input}'" if input
        ret << ":\n #{output}" if output && !output.empty?
        ret
      end
    end

    # Error caused by incorrect usage, usually connected to passed CLI options
    class UsageError < StandardError
    end

    class Validation < StandardError
    end
  end

  class HammerConfigurationError < StandardError
  end
end
