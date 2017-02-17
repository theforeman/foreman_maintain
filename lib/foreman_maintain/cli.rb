require 'clamp'
require 'highline'
require 'foreman_maintain/cli/base'
require 'foreman_maintain/cli/health_command'
require 'foreman_maintain/cli/upgrade_command'
ForemanMaintain.setup

module ForemanMaintain
  module Cli
    class MainCommand < Base
      subcommand 'health', 'Health related commands', HealthCommand
      subcommand 'upgrade', 'Upgrade related commands', UpgradeCommand
      MainCommand.run
    end
  end
end
