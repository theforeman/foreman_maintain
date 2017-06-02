module Scenarios::Satellite_6_2
  class PreMigrations < ForemanMaintain::Scenario
    metadata do
      description 'procedures before migrating to Satellite 6.2'
      tags :pre_migrations, :satellite_6_2
      confine do
        feature(:downstream) && feature(:downstream).current_minor_version == '6.1'
      end
    end

    def compose
      add_steps(find_procedures(:pre_migrations))
    end
  end
end
