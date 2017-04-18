class Scenarios::MissingUpgrade < ForemanMaintain::Scenario
  metadata do
    tags :upgrade, :missing_upgrade
    description 'missing_service upgrade scenario'
    confine do
      feature(:missing_service)
    end
  end

  def compose
    add_steps(find_checks(:default))
  end
end
