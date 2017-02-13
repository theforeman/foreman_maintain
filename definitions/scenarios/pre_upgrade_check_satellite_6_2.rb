class Scenarios::PreUpgradeCheckSatellite_6_2 < ForemanMaintain::Scenario
  requires_feature :downstream

  tags :pre_upgrade_check, :satellite_6_2

  description "checks before upgrading to Satellite 6.2"

  def compose
    steps.concat(find_checks(:basic))
    steps << Checks::ForemanTasksNotRunning.new
  end
end