module Procedures::MaintenanceFile
  class Remove < ForemanMaintain::Procedure
    metadata do
      description 'Remove maintenance_file'
      tags :post_migrations
      for_feature :maintenance_mode
      advanced_run false
      after :cron_start
    end

    def run
      feature(:maintenance_mode).perform_action(:maintenance_file, 'remove')
    end
  end
end
