class Scenarios::PreUpgradeCheckSatellite_6_2 < ForemanMaintain::Scenario
  tags :pre_upgrade_check, :satellite_6_2
  description 'checks before upgrading to Satellite 6.2'
  confine do
    :downstream
  end

  def compose
    steps.concat(find_checks(:basic))
    steps << check(Checks::ForemanTasksNotRunning)
  end
end
