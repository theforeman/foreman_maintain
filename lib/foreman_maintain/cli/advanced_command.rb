require 'foreman_maintain/cli/advanced/procedure_command'

module ForemanMaintain
  module Cli
    class AdvancedCommand < Base
      subcommand 'procedure', 'Run maintain procedures manually', ProcedureCommand
    end
  end
end
