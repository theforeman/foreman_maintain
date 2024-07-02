module Procedures::SyncPlans
  class Disable < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::Hammer
    metadata do
      for_feature :sync_plans
      description 'disable active sync plans'

      confine do
        feature(:katello)
      end
    end

    def run
      disable_all_enabled_sync_plans
    end

    private

    def disable_all_enabled_sync_plans
      default_storage = ForemanMaintain.storage(:default)
      feature(:sync_plans).load_from_storage(default_storage)
      with_spinner('disabling sync plans') do |spinner|
        record_ids = feature(:sync_plans).make_disable
        spinner.update "Total #{record_ids.length} sync plans are now disabled."
      end
    ensure
      feature(:sync_plans).save_to_storage(default_storage)
      default_storage.save
    end
  end
end
