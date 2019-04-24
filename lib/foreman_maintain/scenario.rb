module ForemanMaintain
  class Scenario
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::ScenarioMetadata
    include Concerns::Finders
    extend Concerns::Finders

    attr_reader :steps, :context

    class FilteredScenario < Scenario
      metadata do
        manual_detection
        run_strategy :fail_slow
      end

      attr_reader :filter_label, :filter_tags

      def initialize(filter, definition_kinds = [:check])
        @filter_tags = filter[:tags]
        @filter_label = filter[:label]
        @definition_kinds = definition_kinds
        @steps = []
        @steps += checks(filter) if definition_kinds.include?(:check)
        @steps += procedures(filter) if definition_kinds.include?(:procedure)
        @steps = DependencyGraph.sort(@steps)
      end

      def runtime_message
        if @filter_label
          "#{kind_list} with label [#{dashize(@filter_label)}]"
        else
          "#{kinds_list} with tags #{tag_string(@filter_tags)}"
        end
      end

      private

      def kinds_list
        @definition_kinds.map { |kind| kind.to_s + 's' }.join(' and ')
      end

      def kind_list
        @definition_kinds.map(&:to_s).join(' or ')
      end

      def tag_string(tags)
        tags.map { |tag| dashize("[#{tag}]") }.join(' ')
      end

      def dashize(string)
        string.to_s.tr('_', '-')
      end

      def checks(filter)
        ForemanMaintain.available_checks(filter).map(&:ensure_instance)
      end

      def procedures(filter)
        ForemanMaintain.available_procedures(filter).map(&:ensure_instance)
      end
    end

    class PreparationScenario < Scenario
      metadata do
        manual_detection
        description 'preparation steps required to run the next scenarios'
        run_strategy :fail_slow
      end

      attr_reader :main_scenario

      def initialize(main_scenario)
        @main_scenario = main_scenario
      end

      def steps
        @steps ||= main_scenario.preparation_steps.find_all(&:necessary?)
      end
    end

    def initialize(context_data = {})
      @steps = []
      @context = Context.new(context_data)
      set_context_mapping
      compose
    end

    # Override to compose steps for the scenario
    def compose; end

    # Override to map context for the scenario
    def set_context_mapping; end

    def preparation_steps
      # we first take the preparation steps defined for the scenario + collect
      # preparation steps for the steps inside the scenario
      steps.inject(super.dup) do |results, step|
        results.concat(step.preparation_steps)
      end.uniq
    end

    def executed_steps
      steps.find_all(&:executed?)
    end

    def steps_with_error(options = {})
      filter_whitelisted(executed_steps.find_all(&:fail?), options)
    end

    def steps_with_abort(options = {})
      filter_whitelisted(executed_steps.find_all(&:aborted?), options)
    end

    def steps_with_warning(options = {})
      filter_whitelisted(executed_steps.find_all(&:warning?), options)
    end

    def steps_with_skipped(options = {})
      filter_whitelisted(executed_steps.find_all(&:skipped?), options)
    end

    def filter_whitelisted(steps, options)
      options.validate_options!(:whitelisted)
      if options.key?(:whitelisted)
        steps.select do |step|
          options[:whitelisted] ? step.whitelisted? : !step.whitelisted?
        end
      else
        steps
      end
    end

    def passed?
      (steps_with_abort(:whitelisted => false) +
        steps_with_error(:whitelisted => false)).empty?
    end

    def warning?
      !steps_with_warning(:whitelisted => false).empty?
    end

    def failed?
      !passed?
    end

    # scenarios to be run before this scenario
    def before_scenarios
      scenarios = []
      preparation_scenario = PreparationScenario.new(self)
      scenarios << [preparation_scenario] unless preparation_scenario.steps.empty?
      scenarios
    end

    def add_steps(steps)
      steps.each do |step|
        self.steps << step.ensure_instance
      end
    end

    def add_step(step)
      add_steps([step]) unless step.nil?
    end

    def add_step_with_context(definition, extra_params = {})
      if definition.present?
        add_step(definition.send(:new, context.params_for(definition).merge(extra_params)))
      end
    end

    def add_steps_with_context(*definitions)
      definitions.flatten.each { |definition| add_step_with_context(definition) }
    end

    def self.inspect
      "Scenario Class #{metadata[:description]}<#{name}>"
    end

    def inspect
      "#{self.class.metadata[:description]}<#{self.class.name}>"
    end

    def to_hash
      { :label => label,
        :steps => steps.map(&:to_hash) }
    end

    def self.new_from_hash(hash)
      scenarios = find_all_scenarios(:label => hash[:label])
      unless scenarios.size == 1
        raise "Could not find scenario #{hash[:label]}, found #{scenarios.size} scenarios"
      end
      scenario = scenarios.first
      scenario.load_step_states(hash[:steps])
      scenario
    end

    def load_step_states(steps_hash)
      steps = self.steps.dup
      steps_hash.each do |step_hash|
        until steps.empty?
          step = steps.shift
          if step.matches_hash?(step_hash)
            step.update_from_hash(step_hash)
            break
          end
        end
      end
    end
  end
end
