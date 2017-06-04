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
        versions_to_tags.inject([]) do |available_targets, (version, tag)|
          if !find_scenarios(:tags => [tag]).empty?
            available_targets << version
          else
            available_targets
          end
        end
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
        versions_to_tags.clear
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
      matching_scenarios = find_scenarios(condition)
      raise "Too many scenarios match #{condition.inspect}" if matching_scenarios.size > 1
      @scenario_cache[phase] = matching_scenarios.first
    end

    def run
      phases_to_run.each do |phase|
        break if quit?
        next_scenario = scenario(phase)
        next if next_scenario.nil? || next_scenario.steps.empty?
        run_scenario(next_scenario)
        # if we started from the :pre_upgrade_checks, ensure to ask before
        # continuing with the rest of the upgrade
        @ask_to_confirm_upgrade = (self.phase == :pre_upgrade_checks)
      end
    end

    private

    def confirm_scenario(scenario)
      decision = super(scenario)
      # we have not asked the user already about next steps
      if decision.nil? && @ask_to_confirm_upgrade
        response = reporter.ask_decision(<<-MESSAGE.strip_heredoc.strip)
            The script will now start with the modification part of the upgrade.
            Confirm to continue
        MESSAGE
        ask_to_quit if [:no, :quit].include?(response)
      end
      response
    ensure
      @ask_to_confirm_upgrade = false
    end

    def phases_to_run
      phases_to_run = PHASES.dup
      phases_to_run.shift until phases_to_run.first == phase
      phases_to_run
    end

    def phase=(phase)
      raise "Unknown phase #{phase}" unless PHASES.include?(phase)
      @phase = phase
    end
  end
end
