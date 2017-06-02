module Procedures::MaintenanceMode
  class Disable < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman
      description 'turn off maintenance mode'
      tags :post_migrations
    end

    def run
      feature(:foreman).maintenance_mode(:disable)
    end
  end
end
