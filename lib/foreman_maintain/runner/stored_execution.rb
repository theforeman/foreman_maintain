module ForemanMaintain
  class Runner
    # Class representing an execution of a single step in scenario
    class StoredExecution < Execution
      include Concerns::Logger
      extend Forwardable

      def initialize(step, hash)
        @step = step
        @status = hash[:status]
        @output = hash[:output]
      end

      def reporter
        raise 'Can not access reporter from stored execution'
      end

      def run
        raise 'Can not run stored execution'
      end
    end
  end
end
