module ForemanMaintain
  module Concerns
    module SystemExecutable
      include Logger

      def execute?(command, options = {})
        execute(command, options)
        $CHILD_STATUS.success?
      end

      def execute!(command, options = {})
        command_runner = Utils::CommandRunner.new(logger, command, options)
        execution.puts '' if command_runner.interactive? && respond_to?(:execution)
        command_runner.run
        if command_runner.success?
          command_runner.output
        else
          raise command_runner.execution_error
        end
      end

      def execute(command, options = {})
        command_runner = Utils::CommandRunner.new(logger, command, options)
        execution.puts '' if command_runner.interactive? && respond_to?(:execution)
        command_runner.run
        command_runner.output
      end

      def execute_with_status(command, options = {})
        result_msg = execute(command, options)
        [$CHILD_STATUS.to_i, result_msg]
      end

      def file_exists?(filename)
        File.exist?(filename)
      end
    end
  end
end
