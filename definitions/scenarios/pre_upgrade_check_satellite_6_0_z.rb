class Scenarios::PreUpgradeCheckSatellite_6_0_z < ForemanMaintain::Scenario
  metadata do
    tags :pre_upgrade_check, :satellite_6_0_z
    description 'checks before upgrading to Satellite 6.0'
    confine do
      feature(:downstream) && feature(:downstream).current_version.to_s.start_with?('6.0.')
    end
  end

  def compose
    add_steps(find_checks(:basic))
    add_steps(find_checks(:pre_upgrade))
  end
end
