require 'clamp'
require 'highline'
require 'foreman_maintain/cli/base'
require 'foreman_maintain/cli/health_command'
require 'foreman_maintain/cli/upgrade_command'
require 'foreman_maintain/cli/advanced_command'

module ForemanMaintain
  module Cli
    class MainCommand < Base
      subcommand 'health', 'Health related commands', HealthCommand
      subcommand 'upgrade', 'Upgrade related commands', UpgradeCommand
      subcommand 'advanced', 'Advanced tools for server maintenance', AdvancedCommand
    end
  end
end
