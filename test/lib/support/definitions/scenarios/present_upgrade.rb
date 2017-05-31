class Scenarios::PresentUpgrade < ForemanMaintain::Scenario
  metadata do
    description 'present_service upgrade scenario'
    tags :upgrade, :present_upgrade
    run_strategy :fail_slow

    confine do
      feature(:present_service)
    end
  end

  def compose
    add_steps(find_checks(:default))
    add_step(procedure(Procedures::PresentServiceRestart))
  end
end
