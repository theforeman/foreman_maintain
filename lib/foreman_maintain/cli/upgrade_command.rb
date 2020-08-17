module ForemanMaintain
  module Cli
    class UpgradeCommand < Base
      def self.target_version_option
        option '--target-version', 'TARGET_VERSION', 'Target version of the upgrade',
               :required => false
      end

      def self.disable_self_upgrade_option
        option '--disable-self-upgrade', :flag, 'Disable automatic self upgrade',
               :default => false
      end

      def current_target_version
        current_target_version = ForemanMaintain::UpgradeRunner.current_target_version
        if current_target_version && target_version && target_version != current_target_version
          raise Error::UsageError,
                "Can't set target version #{target_version}, "\
                "#{current_target_version} already in progress"
        end
        @target_version = current_target_version if current_target_version
        return true if current_target_version
      end

      def validate_target_version!
        return if current_target_version
        unless UpgradeRunner.available_targets.include?(target_version)
          message_start = if target_version
                            "Can't upgrade to #{target_version}"
                          else
                            '--target-version not specified'
                          end
          message = <<-MESSAGE.strip_heredoc
            #{message_start}
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
        disable_self_upgrade_option

        def execute
          ForemanMaintain.perform_self_upgrade unless disable_self_upgrade?
          print_versions(UpgradeRunner.available_targets)
        end
      end

      subcommand 'check', 'Run pre-upgrade checks before upgrading to specified version' do
        target_version_option
        interactive_option
        disable_self_upgrade_option

        def execute
          ForemanMaintain.perform_self_upgrade unless disable_self_upgrade?
          upgrade_runner.run_phase(:pre_upgrade_checks)
          exit upgrade_runner.exit_code
        end
      end

      subcommand 'run', 'Run full upgrade to a specified version' do
        target_version_option
        interactive_option
        disable_self_upgrade_option

        option '--phase', 'phase', 'run only a specific phase', :required => false do |phase|
          unless UpgradeRunner::PHASES.include?(phase.to_sym)
            raise Error::UsageError, "Unknown phase #{phase}"
          end
          phase
        end

        def execute
          ForemanMaintain.perform_self_upgrade unless disable_self_upgrade?
          if phase
            upgrade_runner.run_phase(phase.to_sym)
          else
            upgrade_runner.run
          end
          upgrade_runner.save
          exit upgrade_runner.exit_code
        end
      end
    end
  end
end
