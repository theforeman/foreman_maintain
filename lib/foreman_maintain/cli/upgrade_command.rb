module ForemanMaintain
  module Cli
    class UpgradeCommand < Base
      def validate_target_version!
        raise Error::UsageError, 'target version not specified' unless target_version
        unless UpgradeRunner.available_targets.include?(target_version)
          message = <<-MESSAGE.strip_heredoc
            Can't upgrade to #{target_version}
            Possible target versions are:
          MESSAGE
          versions = UpgradeRunner.available_targets.join("\n")
          raise Error::UsageError, message + versions
        end
      end

      def upgrade_runner
        return @upgrade_runner if defined? @upgrade_runner
        validate_target_version!
        @upgrade_runner = ForemanMaintain::UpgradeRunner.new(target_version, reporter,
                                                             :assumeyes => assumeyes?,
                                                             :whitelist => whitelist || [],
                                                             :force => force?).tap(&:load)
      end

      def print_versions(target_versions)
        target_versions.sort.each { |version| puts version }
      end

      subcommand 'list-versions', 'List versions this system is upgradable to' do
        def execute
          print_versions(UpgradeRunner.available_targets)
        end
      end

      subcommand 'check', 'Run pre-upgrade checks before upgrading to specified version' do
        parameter 'TARGET_VERSION', 'Target version of the upgrade', :required => false
        interactive_option

        def execute
          upgrade_runner.run_phase(:pre_upgrade_checks)
          exit upgrade_runner.exit_code
        end
      end

      subcommand 'advanced', 'Advanced commands: use with caution' do
        subcommand 'run', 'Run specific phase of the upgrade' do
          option '--phase', 'phase', 'phase to be run', :required => true
          parameter 'TARGET_VERSION', 'Target version of the upgrade', :required => false
          interactive_option

          def execute
            upgrade_runner.run_phase(phase.to_sym)
            exit upgrade_runner.exit_code
          end
        end
      end

      subcommand 'run', 'Run full upgrade to a specified version' do
        parameter 'TARGET_VERSION', 'Target version of the upgrade', :required => false
        interactive_option

        def execute
          upgrade_runner.run
          upgrade_runner.save
          exit upgrade_runner.exit_code
        end
      end
    end
  end
end
