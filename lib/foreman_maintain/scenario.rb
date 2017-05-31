module ForemanMaintain
  class Scenario
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders

    attr_reader :steps

    class FilteredScenario < Scenario
      metadata { manual_detection }

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
      end

      attr_reader :main_scenario

      def initialize(main_scenario)
        @main_scenario = main_scenario
      end

      def steps
        @steps ||= main_scenario.preparation_steps.find_all(&:necessary?)
      end
    end

    def initialize
      @steps = []
      compose
    end

    # Override to compose steps for the scenario
    def compose; end

    def preparation_steps
      # we first take the preparation steps defined for the scenario + collect
      # preparation steps for the steps inside the scenario
      steps.inject(super.dup) do |results, step|
        results.concat(step.preparation_steps)
      end.uniq
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
      add_steps([step])
    end

    def self.inspect
      "Scenario Class #{metadata[:description]}<#{name}>"
    end

    def inspect
      "#{self.class.metadata[:description]}<#{self.class.name}>"
    end
  end
end
