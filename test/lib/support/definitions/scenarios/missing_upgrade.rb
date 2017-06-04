module Scenarios::MissingUpgrade
  class PreUpgradeChecks < ForemanMaintain::Scenario
    metadata do
      tags :upgrade, :missing_upgrade, :pre_upgrade_checks
      description 'missing_service upgrade scenario'
      confine do
        feature(:missing_service)
      end
    end

    def compose
      add_steps(find_checks(:default))
    end
  end
end

ForemanMaintain::UpgradeRunner.register_version('1.14', :missing_upgrade)
