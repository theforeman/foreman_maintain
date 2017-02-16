class Scenarios::PreUpgradeCheckForeman_1_14 < ForemanMaintain::Scenario
  description 'checks before upgrading to Foreman 1.14'
  confine do
    feature(:upstream)
  end

  tags :pre_upgrade_check

  def compose
    steps.concat(find_checks(:basic))
  end
end
