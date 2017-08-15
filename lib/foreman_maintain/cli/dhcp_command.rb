require 'foreman_maintain/cli/advanced/procedure/abstract_procedure_command'
module ForemanMaintain
  module Cli
    class DhcpCommand < Base
      dhcp_procedures = ForemanMaintain.available_procedures(:tags => :dhcp_reservations)
      dhcp_procedures.each do |procedure|
        klass = Class.new(Procedure::AbstractProcedureCommand) do
          params_to_options(procedure.params)
          interactive_option
        end
        subcommand(dashize(procedure.label), procedure.description, klass)
      end

      def execute
        puts help
      end
    end
  end
end
