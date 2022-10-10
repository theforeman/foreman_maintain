require 'foreman_maintain/cli/advanced/procedure_command'
require 'foreman_maintain/cli/advanced/prebuild_bash_completion'

module ForemanMaintain
  module Cli
    class AdvancedCommand < Base
      subcommand 'procedure', 'Run maintain procedures manually', ProcedureCommand
      subcommand 'prebuild-bash-completion',
        'Prepare map of options and subcommands for Bash completion',
        PrebuildBashCompletionCommand
    end
  end
end
