module Procedures::SyncPlans
  class Enable < ForemanMaintain::Procedure
    metadata do
      for_feature :sync_plans
      description 're-enable active sync plans'
    end

    def run
      enabled_sync_plans
    end

    private

    def enabled_sync_plans
      feature(:sync_plans).make_enable
    end
  end
end
