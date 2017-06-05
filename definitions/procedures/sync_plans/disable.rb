module Procedures::SyncPlans
  class Disable < ForemanMaintain::Procedure
    metadata do
      for_feature :sync_plans
      description 'disable active sync plans'
      tags :pre_migrations
    end

    def run
      disable_all_enabled_sync_plans
    end

    private

    def disable_all_enabled_sync_plans
      feature(:sync_plans).load_from_storage(storage)
      with_spinner('disabling sync plans') do |spinner|
        ids = feature(:sync_plans).ids_by_status(true)
        feature(:sync_plans).make_disable(ids)
        spinner.update "Total #{ids.length} sync plans are now disabled."
      end
    ensure
      feature(:sync_plans).save_to_storage(storage)
    end
  end
end
