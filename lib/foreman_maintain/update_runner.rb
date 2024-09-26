module ForemanMaintain
  class UpdateRunner < Runner
    include Concerns::Finders

    PHASES = [
      :pre_update_checks,
      :pre_migrations,
      :migrations,
      :post_migrations,
      :post_update_checks,
    ].freeze

    attr_reader :phase

    def initialize(reporter, options = {})
      super(reporter, [], options)
      @scenario_cache = {}
      self.phase = :pre_update_checks
    end

    def available?
      condition = { :tags => [:update_scenario, :pre_update_checks] }
      matching_scenarios = find_scenarios(condition)
      !matching_scenarios.empty?
    end

    def find_scenario(phase)
      return @scenario_cache[phase] if @scenario_cache.key?(phase)

      condition = { :tags => [:update_scenario, phase] }
      matching_scenarios = find_scenarios(condition)
      @scenario_cache[phase] = matching_scenarios.first
    end

    def run
      PHASES.each do |phase|
        return run_rollback if quit?

        if skip?(phase)
          skip_phase(phase)
        else
          run_phase(phase)
        end
      end

      finish_update unless quit?
    end

    def run_rollback
      # we only are able to rollback from pre_migrations phase
      if phase == :pre_migrations
        rollback_pre_migrations
      end
    end

    def finish_update
      @finished = true
      @reporter.hline
      @reporter.puts("Update finished.\n")
    end

    def storage
      ForemanMaintain.storage("update")
    end

    # serializes the state of the run to storage
    def save
      if @finished
        storage.delete(:serialized)
      else
        storage[:serialized] = to_hash
      end
      storage.save
    end

    # deserializes the state of the run from the storage
    def load
      return unless storage[:serialized]

      load_from_hash(storage[:serialized])
    end

    def run_phase(phase)
      scenario = find_scenario(phase)
      return if scenario.nil? || scenario.steps.empty?

      confirm_scenario(scenario)
      return if quit?

      self.phase = phase
      run_scenario(scenario)
      # if we started from the :pre_update_checks, ensure to ask before
      # continuing with the rest of the update
      @ask_to_confirm_update = phase == :pre_update_checks
    end

    def skip_phase(skipped_phase)
      with_non_empty_scenario(skipped_phase) do |scenario|
        @reporter.before_scenario_starts(scenario)
        @reporter.puts <<~MESSAGE
          Skipping #{skipped_phase} phase as it was already run before.
        MESSAGE
        @reporter.after_scenario_finishes(scenario)
      end
    end

    private

    def rollback_pre_migrations
      raise "Unexpected phase #{phase}, expecting pre_migrations" unless phase == :pre_migrations

      rollback_needed = scenario(:pre_migrations).steps.any? { |s| s.executed? && s.success? }
      if rollback_needed
        @quit = false
        # prevent the unnecessary confirmation questions
        @last_scenario = nil
        @last_scenario_continuation_confirmed = true
        [:post_migrations, :post_update_checks].each do |phase|
          run_phase(phase)
        end
      end
      self.phase = :pre_update_checks # rollback finished
      @reporter.puts("The update failed and system was restored to pre-update state.")
    end

    def with_non_empty_scenario(phase)
      next_scenario = find_scenario(phase)
      unless next_scenario.nil? || next_scenario.steps.empty?
        yield next_scenario
      end
    end

    def to_hash
      ret = { :phase => phase, :scenarios => {} }
      @scenario_cache.each do |key, scenario|
        ret[:scenarios][key] = scenario.to_hash
      end
      ret
    end

    def load_from_hash(hash)
      unless @scenario_cache.empty?
        raise "Some scenarios are already initialized: #{@scenario_cache.keys}"
      end

      self.phase = hash[:phase]
      hash[:scenarios].each do |key, scenario_hash|
        @scenario_cache[key] = Scenario.new_from_hash(scenario_hash)
      end
    end

    def confirm_scenario(scenario)
      decision = super(scenario)
      # we have not asked the user already about next steps
      if decision.nil? && @ask_to_confirm_update
        response = reporter.ask_decision(<<~MESSAGE.strip)
          The pre-update checks indicate that the system is ready for update.
          It's recommended to perform a backup at this stage.
          Confirm to continue with the modification part of the update
        MESSAGE
        if [:no, :quit].include?(response)
          ask_to_quit
        end
      end
      response
    ensure
      @ask_to_confirm_update = false
    end

    def skip?(next_phase)
      # the next_phase was run before the current phase
      PHASES.index(next_phase) < PHASES.index(phase)
    end

    def phase=(phase)
      raise "Unknown phase #{phase}" unless PHASES.include?(phase)

      @phase = phase
    end
  end
end
