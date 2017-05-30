module Checks::SyncPlans
  class WithEnabledStatus < ForemanMaintain::Check
    include ForemanMaintain::Concerns::Hammer

    metadata do
      for_feature :sync_plans
      description 'check for enabled sync plans'
      tags :pre_upgrade
      before :disk_io
    end

    def run
      active_sync_plans_count = feature(:sync_plans).active_sync_plans_count
      assert(active_sync_plans_count == 0,
             "There are total #{active_sync_plans_count} active sync plans in the system",
             :next_steps => Procedures::SyncPlans::Disable.new)
    end
  end
end
