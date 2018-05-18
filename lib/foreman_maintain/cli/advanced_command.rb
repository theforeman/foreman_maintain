require 'foreman_maintain/cli/advanced/procedure_command'
require 'foreman_maintain/cli/advanced/prebuild_bash_completion'
require 'foreman_maintain/cli/advanced/task_cleanup_command'

module ForemanMaintain
  module Cli
    class AdvancedCommand < Base
      subcommand 'procedure', 'Run maintain procedures manually', ProcedureCommand
      subcommand 'prebuild-bash-completion',
                 'Prepare map of options and subcommands for Bash completion',
                 PrebuildBashCompletionCommand
      subcommand 'task-cleanup', 'Perform task cleanup', TaskCleanupCommand
    end
  end
end
