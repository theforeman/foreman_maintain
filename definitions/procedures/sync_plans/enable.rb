module Procedures::SyncPlans
  class Enable < ForemanMaintain::Procedure
    metadata do
      for_feature :sync_plans
      description 're-enable sync plans'
      tags :post_migrations
      before :disk_io

      confine do
        feature(:katello)
      end
    end

    def run
      enabled_sync_plans
    end

    private

    def enabled_sync_plans
      feature(:sync_plans).load_from_storage(storage)
      with_spinner('re-enabling sync plans') do |spinner|
        record_ids = feature(:sync_plans).make_enable
        spinner.update "Total #{record_ids.length} sync plans are now enabled."
      end
    ensure
      feature(:sync_plans).save_to_storage(storage)
    end
  end
end
