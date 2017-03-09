module Checks::SyncPlans
  class WithDisabledStatus < ForemanMaintain::Check
    metadata do
      for_feature :sync_plans
      description 'check for disabled sync plans'
      tags :post_upgrade
    end

    def run
      disabled_plans_count = feature(:sync_plans).disabled_plans_count
      assert(disabled_plans_count == 0,
             "There are #{disabled_plans_count} disabled sync plans which needs to be enabled",
             :next_steps => Procedures::SyncPlans::Enable.new)
    end
  end
end
