module ForemanMaintain
  module Error
    class Fail < StandardError
    end

    class Warn < StandardError
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
  end
end
