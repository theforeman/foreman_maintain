module Scenarios::Satellite_6_2
  class PostUpgradeCheck < ForemanMaintain::Scenario
    metadata do
      description 'checks after upgrading to Satellite 6.2'
      tags :post_upgrade_check, :satellite_6_2
      confine do
        feature(:downstream) && feature(:downstream).current_minor_version == '6.1'
      end
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:post_upgrade))
    end
  end
end
