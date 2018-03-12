module ForemanMaintain
  module Cli
    module Procedure
      class AbstractReportCommand < Base
        def execute
          label = invocation_path.split.last.underscorize
          procedure = procedure(label.to_sym)
          scenario = ForemanMaintain::Scenario.new
          scenario.add_step(procedure.new)
          run_scenario(scenario)
        end
      end
    end
  end
end
