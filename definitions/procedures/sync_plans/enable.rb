module Procedures::SyncPlans
  class Enable < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::Hammer
    metadata do
      for_feature :sync_plans
      description 're-enable sync plans'

      confine do
        feature(:katello)
      end
    end

    def run
      enabled_sync_plans
    end

    private

    def enabled_sync_plans
      default_storage = ForemanMaintain.storage(:default)
      feature(:sync_plans).load_from_storage(default_storage)
      with_spinner('re-enabling sync plans') do |spinner|
        record_ids = feature(:sync_plans).make_enable
        spinner.update "Total #{record_ids.length} sync plans are now enabled."
      end
    ensure
      feature(:sync_plans).save_to_storage(default_storage)
      default_storage.save
    end
  end
end
