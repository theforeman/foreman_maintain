module Scenarios::Satellite_6_2
  class PreUpgradeCheck < ForemanMaintain::Scenario
    metadata do
      description 'checks before upgrading to Satellite 6.2'
      tags :pre_upgrade_check, :satellite_6_2
      confine do
        feature(:downstream) && feature(:downstream).current_minor_version == '6.1'
      end
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:pre_upgrade))
    end
  end
end
