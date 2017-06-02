module Procedures::SyncPlans
  class Enable < ForemanMaintain::Procedure
    metadata do
      for_feature :sync_plans
      description 're-enable sync plans'
      tags :post_migrations
      before :disk_io
    end

    def run
      enabled_sync_plans
    end

    private

    def enabled_sync_plans
      with_spinner('re-enabling sync plans') do |spinner|
        record_ids = feature(:sync_plans).make_enable
        spinner.update "Total #{record_ids.length} sync plans are now enabled."
      end
    end
  end
end
