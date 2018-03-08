module ForemanMaintain
  class UpgradeRunner < Runner
    include Concerns::Finders

    # Phases of the upgrade, see README.md for more info
    PHASES = [:pre_upgrade_checks,
              :pre_migrations,
              :migrations,
              :post_migrations,
              :post_upgrade_checks].freeze

    class << self
      include Concerns::Finders

      def available_targets
        # when some upgrade is in progress, we don't allow upgrade to different version
        return [current_target_version] if current_target_version
        versions_to_tags.inject([]) do |available_targets, (version, tag)|
          if !find_scenarios(:tags => [tag]).empty?
            available_targets << version
          else
            available_targets
          end
        end.sort
      end

      def versions_to_tags
        @versions_to_tags ||= {}
      end

      # registers target version to specific tag
      def register_version(version, tag)
        if versions_to_tags.key?(version) && versions_to_tags[version] != tag
          raise "Version #{version} already registered to tag #{versions_to_tags[version]}"
        end
        @versions_to_tags[version] = tag
      end

      def clear_register
        versions_to_tags.lear
      end

      def current_target_version
        ForemanMaintain.storage[:upgrade_target_version]
      end

      def current_target_version=(value)
        ForemanMaintain.storage.update_and_save(:upgrade_target_version => value)
      end

      def clear_current_target_version
        ForemanMaintain.storage.update_and_save(:upgrade_target_version => nil)
      end
    end

    attr_reader :version, :tag, :phase

    def initialize(version, reporter, options = {})
      super(reporter, [], options)
      @tag = self.class.versions_to_tags[version]
      raise "Unknown version #{version}" unless tag
      @version = version
      @scenario_cache = {}
      self.phase = :pre_upgrade_checks
    end

    def scenario(phase)
      return @scenario_cache[phase] if @scenario_cache.key?(phase)
      condition = { :tags => [tag, phase] }
      matching_scenarios = find_all_scenarios(condition)
      raise "Too many scenarios match #{condition.inspect}" if matching_scenarios.size > 1
      @scenario_cache[phase] = matching_scenarios.first
    end

    def run
      self.class.current_target_version = @version
      PHASES.each do |phase|
        return run_rollback if quit?
        if skip?(phase)
          skip_phase(phase)
        else
          run_phase(phase)
        end
      end
      unless quit?
        finish_upgrade
      end
    ensure
      update_current_target_version
    end

    def update_current_target_version
      if phase == :pre_upgrade_checks || @finished
        UpgradeRunner.clear_current_target_version
      end
    end

    def run_rollback
      # we only are able to rollback from pre_migrations phase
      if phase == :pre_migrations
        rollback_pre_migrations
      end
    end

    def finish_upgrade
      @finished = true
      @reporter.hline
      @reporter.puts <<-MESSAGE.strip_heredoc
        Upgrade finished.
      MESSAGE
    end

    def storage
      ForemanMaintain.storage("upgrade_#{version}")
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
      with_non_empty_scenario(phase) do |scenario|
        confirm_scenario(scenario)
        return if quit?
        self.phase = phase
        run_scenario(scenario, false)
        # if we started from the :pre_upgrade_checks, ensure to ask before
        # continuing with the rest of the upgrade
        @ask_to_confirm_upgrade = phase == :pre_upgrade_checks
      end
    end

    def skip_phase(skipped_phase)
      with_non_empty_scenario(skipped_phase) do |scenario|
        @reporter.before_scenario_starts(scenario)
        @reporter.puts <<-MESSAGE.strip_heredoc
          Skipping #{skipped_phase} phase as it was already run before.
          To enforce to run the phase, use `upgrade run --phase #{skipped_phase}`
        MESSAGE
        @reporter.after_scenario_finishes(scenario)
      end
    end

    private

    # rubocop:disable Metrics/AbcSize
    def rollback_pre_migrations
      raise "Unexpected phase #{phase}, expecting pre_migrations" unless phase == :pre_migrations
      rollback_needed = scenario(:pre_migrations).steps.any? { |s| s.executed? && s.success? }
      if rollback_needed
        @quit = false
        @last_scenario = nil # to prevent the unnecessary confirmation questions
        [:post_migrations, :post_upgrade_checks].each do |phase|
          if quit? && phase == :post_upgrade_checks
            self.phase = :pre_migrations
            return # rubocop:disable Lint/NonLocalExitFromIterator
          end
          run_phase(phase)
        end
      end
      self.phase = :pre_upgrade_checks # rollback finished
      @reporter.puts <<-MESSAGE.strip_heredoc
        The upgrade failed and system was restored to pre-upgrade state.
      MESSAGE
    end
    # rubocop:enable Metrics/AbcSize

    def with_non_empty_scenario(phase)
      next_scenario = scenario(phase)
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
      if decision.nil? && @ask_to_confirm_upgrade
        response = reporter.ask_decision(<<-MESSAGE.strip_heredoc.strip)
            The pre-upgrade checks indicate that the system is ready for upgrade.
            It's recommended to perform a backup at this stage.
            Confirm to continue with the modification part of the upgrade
        MESSAGE
        if [:no, :quit].include?(response)
          ask_to_quit
        end
      end
      response
    ensure
      @ask_to_confirm_upgrade = false
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
