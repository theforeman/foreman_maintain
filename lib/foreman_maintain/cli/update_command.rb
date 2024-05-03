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

      subcommand 'check', 'Run pre-update checks before updating' do
        interactive_option
        disable_self_update_option

        def execute
          ForemanMaintain.validate_downstream_packages
          ForemanMaintain.perform_self_upgrade unless disable_self_update?
          runner = update_runner
          runner.run_phase(:pre_update_checks)
          exit runner.exit_code
        end
      end

      subcommand 'run', 'Run an update' do
        interactive_option
        disable_self_update_option

        def execute
          ForemanMaintain.validate_downstream_packages
          ForemanMaintain.perform_self_upgrade unless disable_self_update?
          runner = update_runner
          runner.run
          runner.save
          exit runner.exit_code
        end
      end
    end
  end
end
