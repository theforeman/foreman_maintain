module ForemanMaintain
  module Cli
    class UpgradeCommand < Base
      def self.disable_self_upgrade_option
        option '--disable-self-upgrade', :flag, 'Disable automatic self upgrade',
          :default => false
      end

      def upgrade_runner
        return @upgrade_runner if defined? @upgrade_runner
        @upgrade_runner = ForemanMaintain::UpgradeRunner.new(reporter,
          :assumeyes => assumeyes?,
          :whitelist => whitelist || [],
          :force => force?).tap(&:load)
      end

      def allow_self_upgrade?
        !disable_self_upgrade?
      end

      def try_upgrade
        if upgrade_runner.available?
          yield
        else
          instance = ForemanMaintain.detector.feature(:instance)
          msg = <<~BANNER

            There are no upgrades available.
            The current version of #{instance.product_name} is #{instance.current_major_version}.
            Consider using the update command.
          BANNER

          puts msg
          ForemanMaintain::UpgradeRunner::WARNING_EXIT_CODE
        end
      end

      subcommand 'check', 'Run pre-upgrade checks before upgrading to specified version' do
        interactive_option
        disable_self_upgrade_option

        def execute
          ForemanMaintain.validate_downstream_packages
          ForemanMaintain.perform_self_upgrade if allow_self_upgrade?

          exit_code = try_upgrade do
            upgrade_runner.run_phase(:pre_upgrade_checks)
            upgrade_runner.exit_code
          end

          exit exit_code
        end
      end

      subcommand 'run', 'Run full upgrade to a specified version' do
        interactive_option
        disable_self_upgrade_option

        def execute
          ForemanMaintain.validate_downstream_packages
          ForemanMaintain.perform_self_upgrade if allow_self_upgrade?

          exit_code = try_upgrade do
            upgrade_runner.run
            upgrade_runner.save
            upgrade_runner.exit_code
          end

          exit exit_code
        end
      end
    end
  end
end
