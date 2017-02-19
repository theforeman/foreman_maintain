class Scenarios::MissingUpgrade < ForemanMaintain::Scenario
  confine do
    feature(:missing_service)
  end

  tags :upgrade, :missing_upgrade

  description 'missing_service upgrade scenario'

  def compose
    steps.concat(find_checks(:basic))
  end
end
