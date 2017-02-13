class Scenarios::Upgrade1 < ForemanMaintain::Scenario
  requires_feature :my_test_feature

  tags :upgrade, :upgrade_1

  description 'my_test upgrade scenario'

  def compose
    steps.concat(find_checks(:basic))
  end
end
