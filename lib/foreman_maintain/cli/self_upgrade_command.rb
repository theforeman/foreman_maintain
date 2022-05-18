module ForemanMaintain
  module Cli
    class SelfUpgradeCommand < Base
      option ['--maintenance-repo-label'], 'REPOSITORY_LABEL',\
             'Repository label from which packages should be updated.'\
             'This can be used when standard CDN repositories are unavailable.'
      def execute
        run_scenario(upgrade_scenario)
      end

      def upgrade_scenario
        Scenarios::SelfUpgrade.new(
          maintenance_repo_label: maintenance_repo_label
        )
      end
    end
  end
end
