require 'clamp'
require 'highline'
require 'foreman_maintain/cli/base'
require 'foreman_maintain/cli/health_command'
require 'foreman_maintain/cli/upgrade_command'

module ForemanMaintain
  module Cli
    class MainCommand < Base
      include Concerns::Logger

      subcommand 'health', 'Health related commands', HealthCommand
      subcommand 'upgrade', 'Upgrade related commands', UpgradeCommand

      def run(*arguments)
        logger.info("Running foreman-maintain command with arguments #{arguments.inspect}")
        begin
          super
          exit_code = 0
        rescue StandardError => e
          if e.is_a?(Clamp::HelpWanted) || e.is_a?(ArgumentError) || e.is_a?(Clamp::UsageError)
            raise e
          end
          puts e.message
          logger.error(e)
          exit_code = 1
        end
        return exit_code
      ensure
        logger.info("foreman-maintain command finished with #{exit_code}")
      end
    end
  end
end
