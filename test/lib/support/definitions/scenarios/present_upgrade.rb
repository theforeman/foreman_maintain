class Scenarios::PresentUpgrade < ForemanMaintain::Scenario
  metadata do
    description 'present_service upgrade scenario'
    tags :upgrade, :present_upgrade

    confine do
      feature(:present_service)
    end
  end

  def compose
    steps.concat(find_checks(:basic))
    steps << procedure(Procedures::PresentServiceRestart)
  end
end
