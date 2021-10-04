module ForemanMaintain
  module Cli
    class SelfUpgradeCommand < Base
      option ['--target-version'], 'TARGET_VERSION', 'Major version of the Satellite or Capsule'\
      														 ', e.g 7.0', :required => true
      def execute
        allow_major_version_upgrade_only
        run_scenario(upgrade_scenario, upgrade_rescue_scenario)
      end

      def upgrade_scenario
        Scenarios::SelfUpgrade.new(target_version: target_version)
      end

      def upgrade_rescue_scenario
        Scenarios::SelfUpgradeRescue.new(target_version: target_version)
      end

      def current_downstream_version
        ForemanMaintain.detector.feature(:instance).downstream.current_version
      end

      def allow_major_version_upgrade_only
        begin
          next_version = Gem::Version.new(target_version)
        rescue ArgumentError => err
          raise Error::UsageError, "Invalid version! #{err}"
        end
        output = current_downstream_version.<=>(next_version)
        unless output.negative?
          message = "The target-version #{target_version} should be "\
                    "greater than existing version #{current_downstream_version}!"
          raise Error::UsageError, message
        end
      end
    end
  end
end
