class Scenarios::Upgrade1 < ForemanMaintain::Scenario
  confine do
    feature(:my_test_feature)
  end

  tags :upgrade, :upgrade_1

  description 'my_test upgrade scenario'

  def compose
    steps.concat(find_checks(:basic))
  end
end
