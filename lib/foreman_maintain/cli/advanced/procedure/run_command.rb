require 'foreman_maintain/cli/advanced/procedure/abstract_procedure_command'

module ForemanMaintain
  module Cli
    module Procedure
      class RunCommand < Base
        ForemanMaintain.available_procedures(nil).each do |procedure|
          klass = Class.new(AbstractProcedureCommand) do
            params_to_options(procedure.params)
            interactive_option
          end
          subcommand(dashize(procedure.label), procedure.description, klass)
        end
      end
    end
  end
end
