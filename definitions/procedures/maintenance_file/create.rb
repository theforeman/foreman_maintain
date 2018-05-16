module Procedures::MaintenanceFile
  class Create < ForemanMaintain::Procedure
    metadata do
      description 'Create maintenance_file'
      tags :pre_migrations
      for_feature :maintenance_mode
      advanced_run false
      after :cron_stop
    end

    def run
      feature(:maintenance_mode).perform_action(:maintenance_file, 'create')
    end
  end
end
