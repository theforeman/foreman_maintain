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
require 'foreman_maintain/cli/plugin_command'
require 'foreman_maintain/cli/report_command'
require 'foreman_maintain/cli/self_upgrade_command'
require 'foreman_maintain/cli/update_command'

Clamp.allow_options_after_parameters = true

module ForemanMaintain
  module Cli
    class MainCommand < Base
      include Concerns::Logger

      subcommand 'health', 'Health related commands', HealthCommand
      subcommand 'upgrade', 'Upgrade related commands', UpgradeCommand
      subcommand 'update', 'Update related commands', UpdateCommand
      subcommand 'service', 'Control applicable services', ServiceCommand
      subcommand 'backup', 'Backup server', BackupCommand
      subcommand 'restore', 'Restore a backup', RestoreCommand
      subcommand 'packages', 'Lock/Unlock package protection, install, update', PackagesCommand
      subcommand 'advanced', 'Advanced tools for server maintenance', AdvancedCommand
      subcommand 'plugin', 'Manage optional plugins on your server', PluginCommand
      subcommand 'self-upgrade', 'Perform major version self upgrade', SelfUpgradeCommand
      subcommand 'maintenance-mode', 'Control maintenance-mode for application',
        MaintenanceModeCommand
      subcommand 'report', 'Generate usage report', ReportCommand

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
      end

      private

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
        $stderr.puts error.message
        exit!
      end
    end
  end
end
