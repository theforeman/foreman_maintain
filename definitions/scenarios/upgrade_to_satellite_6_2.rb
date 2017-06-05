module Scenarios::Satellite_6_2
  class Abstract < ForemanMaintain::Scenario
    def self.upgrade_metadata(&block)
      metadata do
        tags :upgrade_to_satellite_6_2
        confine do
          feature(:downstream) && feature(:downstream).current_minor_version == '6.1'
        end
        instance_eval(&block)
      end
    end
  end

  class PreUpgradeCheck < Abstract
    upgrade_metadata do
      description 'checks before upgrading to Satellite 6.2'
      tags :pre_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:pre_upgrade))
    end
  end

  class PreMigrations < ForemanMaintain::Scenario
    metadata do
      description 'procedures before migrating to Satellite 6.2'
      tags :pre_migrations, :upgrade_to_satellite_6_2
      confine do
        feature(:downstream) && feature(:downstream).current_minor_version == '6.1'
      end
    end

    def compose
      add_steps(find_procedures(:pre_migrations))
    end
  end

  class Migrations < ForemanMaintain::Scenario
    metadata do
      description 'migration scripts to Satellite 6.2'
      tags :migrations, :upgrade_to_satellite_6_2
      confine do
        feature(:downstream) && feature(:downstream).current_minor_version == '6.1'
      end
    end

    def compose
      add_steps(find_procedures(:label => :installer_upgrade))
    end
  end

  class PostMigrations < ForemanMaintain::Scenario
    metadata do
      description 'procedures after migrating to Satellite 6.2'
      tags :post_migrations, :upgrade_to_satellite_6_2
      confine do
        feature(:downstream) && feature(:downstream).current_minor_version == '6.1'
      end
    end

    def compose
      add_steps(find_procedures(:post_migrations))
    end
  end

  class PostUpgradeChecks < ForemanMaintain::Scenario
    metadata do
      description 'checks after upgrading to Satellite 6.2'
      tags :post_upgrade_checks, :upgrade_to_satellite_6_2
      confine do
        feature(:downstream) && feature(:downstream).current_minor_version == '6.1'
      end
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:post_upgrade))
    end
  end
end

ForemanMaintain::UpgradeRunner.register_version('6.2', :upgrade_to_satellite_6_2)
