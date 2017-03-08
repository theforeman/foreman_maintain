class Scenarios::PreUpgradeCheckForeman_1_14 < ForemanMaintain::Scenario
  metadata do
    description 'checks before upgrading to Foreman 1.14'
    tags :pre_upgrade_check
    confine do
      feature(:upstream)
    end
  end


  def compose
    steps.concat(find_checks(:basic))
  end
end
