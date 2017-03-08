module ForemanMaintain
  class Scenario
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders

    attr_reader :steps

    class FilteredScenario < Scenario
      metadata do
        manual_detection
      end
      attr_reader :filter_label, :filter_tags

      def initialize(filter)
        @filter_tags = filter[:tags]
        @filter_label = filter[:label]
        @steps = ForemanMaintain.available_checks(filter)
      end

      def description
        if @filter_label
          "check with label [#{dashize(@filter_label)}]"
        else
          "checks with tags #{tag_string(@filter_tags)}"
        end
      end

      private

      def tag_string(tags)
        tags.map { |tag| dashize("[#{tag}]") }.join(' ')
      end

      def dashize(string)
        string.to_s.tr('_', '-')
      end
    end

    def initialize
      @steps = []
      compose
    end

    # Override to compose steps for the scenario
    def compose; end

    def self.inspect
      "Scenario Class #{metadata[:description]}<#{name}>"
    end

    def inspect
      "#{self.class.metadata[:description]}<#{self.class.name}>"
    end
  end
end
