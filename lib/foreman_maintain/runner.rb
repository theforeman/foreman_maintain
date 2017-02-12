module ForemanMaintain
  # Class responsible for running the scenario
  class Runner

    # Class representing an execution of a single step in scenario
    class Execution
      include Concerns::Logger

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
        @output = ""
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

      def run
        @status = :running
        @reporter.before_execution_starts(self)
        with_metadata_calculation do
          step.__run__(self)
        end
        # change the state only when not modified
        @status = :success if @status == :running
      rescue => e
        @status = :fail
        @output << e.message
        logger.error(e)
      ensure
        @reporter.after_execution_finishes(self)
      end

      def with_metadata_calculation
        @started_at = Time.now
        yield
      ensure
        @ended_at = Time.now
      end

      def update(line)
        @reporter.on_execution_update(self, line)
      end
    end

    def initialize(reporter, scenario)
      @reporter = reporter
      @scenario = scenario
      @executions = []
    end

    def run
      @reporter.before_scenario_starts(@scenario)
      @scenario.steps.each do |step|
        execution = Execution.new(step, @reporter)
        execution.run
        @executions << execution
      end
      @reporter.after_scenario_finishes(@scenario)
    end
  end
end