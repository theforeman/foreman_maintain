module ForemanMaintain
  module Cli
    class SelfUpgradeCommand < Base
      option ['--target-version'], 'TARGET_VERSION',\
             'Major version of the Satellite or Capsule'\
             ', e.g 6.11', :required => true
      option ['--maintenance-repo-label'], 'REPOSITORY_LABEL',\
             'Repository label from which packages should be updated.'\
             'This can be used when standard CDN repositories are unavailable.'

      def execute
        allow_major_version_upgrade_only
        run_scenario(upgrade_scenario, upgrade_rescue_scenario)
      end

      def upgrade_scenario
        Scenarios::SelfUpgrade.new(target_version: target_version,
                                   maintenance_repo_label: maintenance_repo_label)
      end

      def upgrade_rescue_scenario
        Scenarios::SelfUpgradeRescue.new(target_version: target_version,
                                         maintenance_repo_label: maintenance_repo_label)
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
        if current_downstream_version >= next_version
          message = "The target-version #{target_version} should be "\
                    "greater than existing version #{current_downstream_version},"\
                    "\nand self-upgrade should be used for major version upgrades only!"
          raise Error::UsageError, message
        end
      end
    end
  end
end
