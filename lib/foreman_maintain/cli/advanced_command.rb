require 'foreman_maintain/cli/advanced/procedure_command'
require 'foreman_maintain/cli/advanced/prebuild_bash_completion'

module ForemanMaintain
  module Cli
    class AdvancedCommand < Base
      subcommand 'procedure', 'Run maintain procedures manually', ProcedureCommand
      subcommand 'prebuild-bash-completion',
                 'Prepare map of options and subcommands for Bash completion',
                 PrebuildBashCompletionCommand

      if defined?(Procedures::ForemanTasks)
        procedure = Procedures::ForemanTasks::Cleanup
        klass = Class.new(Procedure::AbstractProcedureCommand) { params_to_options(procedure.params) }
        subcommand(dashize(procedure.label), procedure.description, klass)
      end
    end
  end
end
