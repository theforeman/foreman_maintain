require 'foreman_maintain/cli/advanced/procedure/run_command'
require 'foreman_maintain/cli/advanced/procedure/by_tag_command'

module ForemanMaintain
  module Cli
    class ProcedureCommand < Base
      subcommand 'run', 'Run maintain procedures manually', Procedure::RunCommand
      subcommand 'by-tag', 'Run maintain procedures in bulks', Procedure::ByTagCommand
    end
  end
end
