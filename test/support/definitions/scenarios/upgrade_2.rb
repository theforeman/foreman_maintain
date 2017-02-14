class Scenarios::Upgrade2 < ForemanMaintain::Scenario
  confine do
    feature(:missing_feature)
  end

  tags :upgrade, :upgrade_2

  description 'missing_feature upgrade scenario'

  def compose
    steps.concat(find_checks(:basic))
  end
end
