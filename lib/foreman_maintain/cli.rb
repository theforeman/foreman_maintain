require 'clamp'
require 'highline'
require 'foreman_maintain/cli/base'
require 'foreman_maintain/cli/transform_clamp_options'
require 'foreman_maintain/cli/health_command'
require 'foreman_maintain/cli/upgrade_command'
require 'foreman_maintain/cli/advanced_command'
require 'foreman_maintain/cli/service_command'

module ForemanMaintain
  module Cli
    class MainCommand < Base
      include Concerns::Logger

      subcommand 'health', 'Health related commands', HealthCommand
      subcommand 'upgrade', 'Upgrade related commands', UpgradeCommand
      subcommand 'advanced', 'Advanced tools for server maintenance', AdvancedCommand
      subcommand 'service', 'Control applicable services', ServiceCommand

      def run(*arguments)
        logger.info("Running foreman-maintain command with arguments #{arguments.inspect}")
        begin
          super
          @exit_code = 0
        rescue Error::UsageError => e
          process_usage_error(e)
        rescue StandardError => e
          process_standard_error(e)
        end

        return @exit_code
      ensure
        log_exit_code_info(@exit_code)
      end

      private

      def log_exit_code_info(exit_code)
        logger.info("foreman-maintain command finished with #{exit_code}")
      end

      def process_standard_error(error)
        if error.is_a?(Clamp::HelpWanted) ||
           error.is_a?(ArgumentError) ||
           error.is_a?(Clamp::UsageError)
          raise error
        end

        puts error.message
        logger.error(error)

        @exit_code = 1
      end

      def process_usage_error(error)
        log_exit_code_info(1)
        puts error.message
        exit!
      end
    end
  end
end
