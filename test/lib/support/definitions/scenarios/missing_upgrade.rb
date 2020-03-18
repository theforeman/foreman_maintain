module Scenarios::MissingUpgrade
  class PreUpgradeChecks < ForemanMaintain::Scenario
    metadata do
      tags :upgrade, :missing_upgrade, :pre_upgrade_checks, :upgrade_scenario
      description 'missing_service upgrade scenario'
      confine do
        feature(:missing_service)
      end

      def target_version
        '1.14'
      end
    end

    def compose
      add_steps(find_checks(:default))
    end
  end
end
