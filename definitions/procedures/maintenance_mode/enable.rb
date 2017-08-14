module Procedures::MaintenanceMode
  class Enable < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman
      description 'turn on maintenance mode'
      tags :pre_migrations
    end

    def run
      feature(:foreman).maintenance_mode(:enable)
    end
  end
end
