class Scenarios::PreUpgradeCheckForeman_1_14 < ForemanMaintain::Scenario
  confine do
    feature(:upstream)
  end

  tags :pre_upgrade_check, :foreman_1_14
end
