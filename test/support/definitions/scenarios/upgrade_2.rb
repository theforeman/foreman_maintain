class Scenarios::Upgrade2 < ForemanMaintain::Scenario
  requires_feature :missing_feature

  tags :upgrade, :upgrade_2

  description 'missing_feature upgrade scenario'

  def compose
    steps.concat(find_checks(:basic))
  end
end
