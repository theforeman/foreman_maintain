module ForemanMaintain
  class Runner
    # Class representing an execution of a single step in scenario
    class Execution
      include Concerns::Logger
      extend Forwardable
      def_delegators :reporter, :with_spinner, :puts, :print, :ask, :assumeyes?

      # Step performed as part of the execution
      attr_reader :step

      # Information about timings, collected automatically
      attr_reader :started_at, :ended_at

      # One of :pending, :running, :success, :fail, :skipped
      attr_accessor :status

      # Output of the execution, to be filled by execution step
      attr_accessor :output

      attr_reader :reporter

      def initialize(step, reporter, options = {})
        options.validate_options!(:whitelisted, :storage, :force)
        @step = step
        @reporter = reporter
        @status = :pending
        @output = ''
        @whitelisted = options[:whitelisted]
        @storage = options[:storage]
        @force = options[:force]
      end

      def name
        @step.description
      end

      def whitelisted?
        @whitelisted
      end

      def success?
        [:success, :already_run, :skipped].include?(@status)
      end

      def fail?
        @status == :fail
      end

      def skipped?
        @status == :skipped
      end

      def skip?
        !@force && step.run_once? && step.executed? && step.success?
      end

      def warning?
        @status == :warning
      end

      # yaml storage to preserve key/value pairs between runs.
      def storage
        @storage || ForemanMaintain.storage(:default)
      end

      def run
        @reporter.before_execution_starts(self)

        if skip?
          @status = :already_run
          return
        end

        @status = whitelisted? ? :skipped : :running

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
      rescue StandardError => e
        @status = :fail
        @output << e.message
        logger.error(e)
      end
    end
  end
end
