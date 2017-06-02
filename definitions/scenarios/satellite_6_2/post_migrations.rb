module Scenarios::Satellite_6_2
  class PostMigrations < ForemanMaintain::Scenario
    metadata do
      description 'procedures after migrating to Satellite 6.2'
      tags :post_migrations, :satellite_6_2
      confine do
        feature(:downstream) && feature(:downstream).current_minor_version == '6.1'
      end
    end

    def compose
      add_steps(find_procedures(:post_migrations))
    end
  end
end
