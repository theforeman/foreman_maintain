module ForemanMaintain
  class Scenario
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata

    attr_reader :steps

    def initialize
      @steps = []
      compose
    end

    # Override to compose steps for the scenario
    def compose
    end

    def find_checks(conditions)
      Filter.new(Check, conditions).run.map(&:new)
    end
  end
end

