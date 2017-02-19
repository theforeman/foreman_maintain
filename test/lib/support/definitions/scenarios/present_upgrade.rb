class Scenarios::PresentUpgrade < ForemanMaintain::Scenario
  confine do
    feature(:present_service)
  end

  tags :upgrade, :present_upgrade

  description 'present_service upgrade scenario'

  def compose
    steps.concat(find_checks(:basic))
    steps << procedure(Procedures::PresentServiceRestart)
  end
end
