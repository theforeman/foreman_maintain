class Scenarios::PreUpgradeCheckSatellite_6_2 < ForemanMaintain::Scenario
  metadata do
    description 'checks before upgrading to Satellite 6.2'
    tags :pre_upgrade_check, :satellite_6_2
    confine do
      feature(:downstream) && feature(:downstream).current_version.to_s.start_with?('6.1.')
    end
  end

  def compose
    steps.concat(find_checks(:basic))
    steps.concat(find_checks(:pre_upgrade))
  end
end
