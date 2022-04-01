module ForemanMaintain
  module Cli
    class SelfUpgradeCommand < Base
      option ['--maintenance-repo-label'], 'REPOSITORY_LABEL',\
             'Repository label from which packages should be updated.'\
             'This can be used when standard CDN repositories are unavailable.'
      def execute
        run_scenario(upgrade_scenario, upgrade_rescue_scenario)
      end

      def upgrade_scenario
        Scenarios::SelfUpgrade.new(target_version: allowed_next_version.to_s,
          maintenance_repo_label: maintenance_repo_label)
      end

      def upgrade_rescue_scenario
        Scenarios::SelfUpgradeRescue.new(target_version: allowed_next_version.to_s,
          maintenance_repo_label: maintenance_repo_label)
      end

      def current_downstream_version
        ForemanMaintain.detector.feature(:instance).downstream.current_version
      end

      def allowed_next_version
        current_downstream_version.bump
      end
    end
  end
end
