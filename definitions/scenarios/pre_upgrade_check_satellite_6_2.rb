class Scenarios::PreUpgradeCheckSatellite_6_2 < ForemanMaintain::Scenario
  tags :pre_upgrade_check, :satellite_6_2
  description 'checks before upgrading to Satellite 6.2'
  confine do
    feature(:downstream)
  end

  def compose
    steps.concat(find_checks(:basic))
    steps.concat(find_checks(:pre_upgrade))
  end
end
