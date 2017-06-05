module ForemanMaintain
  module Cli
    class UpgradeCommand < Base
      def validate_target_version!
        unless UpgradeRunner.available_targets.include?(target_version)
          puts "The specified version #{target_version} is unavailable"
          puts 'Possible target versions are:'
          print_versions(UpgradeRunner.available_targets)
          exit 1
        end
      end

      def upgrade_runner
        validate_target_version!
        ForemanMaintain::UpgradeRunner.new(target_version, reporter,
                                           :assumeyes => assumeyes?,
                                           :whitelist => whitelist || [])
      end

      def print_versions(target_versions)
        target_versions.sort.each { |version| puts version }
      end

      subcommand 'list-versions', 'List versions this system is upgradable to' do
        def execute
          print_versions(UpgradeRunner.available_targets)
        end
      end

      subcommand 'check', 'Run pre-upgrade checks for upgrading to specified version' do
        parameter 'TARGET_VERSION', 'Target version of the upgrade', :required => false
        interactive_option

        def execute
          upgrade_runner.run_phase(:pre_upgrade_checks)
          exit upgrade_runner.exit_code
        end
      end

      subcommand 'run', 'Run full upgrade to a specified version' do
        parameter 'TARGET_VERSION', 'Target version of the upgrade', :required => false
        interactive_option

        def execute
          upgrade_runner.run
          exit upgrade_runner.exit_code
        end
      end
    end
  end
end
