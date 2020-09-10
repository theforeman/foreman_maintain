require 'clamp'
require 'highline'
require 'foreman_maintain/cli/base'
require 'foreman_maintain/cli/transform_clamp_options'
require 'foreman_maintain/cli/health_command'
require 'foreman_maintain/cli/upgrade_command'
require 'foreman_maintain/cli/backup_command'
require 'foreman_maintain/cli/advanced_command'
require 'foreman_maintain/cli/service_command'
require 'foreman_maintain/cli/restore_command'
require 'foreman_maintain/cli/maintenance_mode_command'
require 'foreman_maintain/cli/packages_command'
require 'foreman_maintain/cli/content_command'

module ForemanMaintain
  module Cli
    class MainCommand < Base
      include Concerns::Logger

      subcommand 'health', 'Health related commands', HealthCommand
      subcommand 'upgrade', 'Upgrade related commands', UpgradeCommand
      subcommand 'service', 'Control applicable services', ServiceCommand
      subcommand 'backup', 'Backup server', BackupCommand
      subcommand 'restore', 'Restore a backup', RestoreCommand
      subcommand 'packages', 'Lock/Unlock package protection, install, update', PackagesCommand
      subcommand 'advanced', 'Advanced tools for server maintenance', AdvancedCommand
      subcommand 'content', 'Content related commands', ContentCommand
      subcommand 'maintenance-mode', 'Control maintenance-mode for application',
                 MaintenanceModeCommand

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

        $stderr.puts error.message
        logger.error(error)

        @exit_code = 1
      end

      def process_usage_error(error)
        log_exit_code_info(1)
        $stderr.puts error.message
        exit!
      end
    end
  end
end
