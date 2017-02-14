module ForemanMaintain
  class Scenario
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders

    attr_reader :steps

    def initialize
      @steps = []
      compose
    end

    # Override to compose steps for the scenario
    def compose; end
  end
end
