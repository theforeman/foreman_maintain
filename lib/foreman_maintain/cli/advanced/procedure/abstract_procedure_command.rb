module ForemanMaintain
  module Cli
    module Procedure
      class AbstractProcedureCommand < Base
        include ForemanMaintain::Cli::TransformClampOptions

        def execute
          label = underscorize(invocation_path.split.last)
          procedure = procedure(label.to_sym)
          scenario = ForemanMaintain::Scenario.new
          scenario.add_step(procedure.new(get_params_for(procedure)))
          run_scenario(scenario)
        end
      end
    end
  end
end
