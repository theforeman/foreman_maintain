require 'foreman_maintain/update_runner'

module ForemanMaintain
  module Cli
    class UpdateCommand < Base
      def self.disable_self_update_option
        option '--disable-self-update', :flag, 'Disable automatic self update',
          :default => false
      end

      def update_runner
        update_runner = ForemanMaintain::UpdateRunner.new(
          reporter,
          :assumeyes => assumeyes?,
          :whitelist => whitelist || [],
          :force => force?
        )
        update_runner.load
        update_runner
      end

      def try_update
        if update_runner.available?
          yield
        else
          instance = ForemanMaintain.detector.feature(:instance)
          msg = <<~BANNER

            This version of #{ForemanMaintain.command_name} only supports #{instance.target_version},
            but the installed version of #{instance.product_name} is #{instance.current_major_version}.

            Therefore the update command is not available right now.

            Please install a version of #{ForemanMaintain.command_name} that supports #{instance.current_major_version}
            or perform an upgrade to #{instance.target_version} using the upgrade command.
          BANNER

          puts msg
          ForemanMaintain::UpdateRunner::WARNING_EXIT_CODE
        end
      end

      subcommand 'check', 'Run pre-update checks before updating' do
        interactive_option
        disable_self_update_option

        def execute
          ForemanMaintain.validate_downstream_packages
          ForemanMaintain.perform_self_upgrade unless disable_self_update?

          exit_code = try_update do
            runner = update_runner
            runner.run_phase(:pre_update_checks)
            runner.exit_code
          end

          exit exit_code
        end
      end

      subcommand 'run', 'Run an update' do
        interactive_option
        disable_self_update_option

        def execute
          ForemanMaintain.validate_downstream_packages
          ForemanMaintain.perform_self_upgrade unless disable_self_update?

          exit_code = try_update do
            runner = update_runner
            runner.run
            runner.save
            runner.exit_code
          end

          exit exit_code
        end
      end
    end
  end
end
