module Scenarios::Satellite_6_2
  class PostMigrations < ForemanMaintain::Scenario
    metadata do
      description 'checks before upgrading to Satellite 6.2'
      tags :post_migrations, :satellite_6_2
      confine do
        feature(:downstream) && feature(:downstream).current_minor_version == '6.1'
      end
    end

    def compose
      add_steps(find_checks(:post_migration))
    end
  end
end
