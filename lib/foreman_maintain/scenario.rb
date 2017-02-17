module ForemanMaintain
  class Scenario
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders

    attr_reader :steps

    class ChecksScenario < Scenario
      manual_detection

      def initialize(filter_tags)
        @filter_tags = filter_tags
        @steps = ForemanMaintain.available_checks(:tags => filter_tags)
      end

      def description
        "checks with tags #{tag_string(@filter_tags)}"
      end

      private

      def tag_string(tags)
        tags.map { |tag| "[#{tag}]" }.join(' ')
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
