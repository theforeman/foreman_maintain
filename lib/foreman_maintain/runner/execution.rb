module ForemanMaintain
  class Runner
    # Class representing an execution of a single step in scenario
    class Execution
      include Concerns::Logger
      extend Forwardable
      def_delegators :@reporter, :with_spinner, :puts, :print, :ask

      # Step performed as part of the execution
      attr_reader :step

      # Information about timings, collected automatically
      attr_reader :started_at, :ended_at

      # One of :pending, :running, :success, :fail, :skipped
      attr_accessor :status

      # Output of the execution, to be filled by execution step
      attr_accessor :output

      def initialize(step, reporter)
        @step = step
        @reporter = reporter
        @status = :pending
        @output = ''
      end

      def name
        @step.description
      end

      def success?
        @status == :success
      end

      def fail?
        @status == :fail
      end

      def skipped?
        @status == :skipped
      end

      def run
        @status = :running
        @reporter.before_execution_starts(self)
        with_metadata_calculation do
          capture_errors do
            step.__run__(self)
          end
        end
        # change the state only when not modified
        @status = :success if @status == :running
      ensure
        @reporter.after_execution_finishes(self)
      end

      def update(line)
        @reporter.on_execution_update(self, line)
      end

      private

      def with_metadata_calculation
        @started_at = Time.now
        yield
      ensure
        @ended_at = Time.now
      end

      def capture_errors
        yield
      rescue => e
        @status = :fail
        @output << e.message
        logger.error(e)
      end
    end
  end
end
