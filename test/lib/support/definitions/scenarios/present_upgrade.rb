module Scenarios::PresentUpgrade
  class PreUpgradeChecks < ForemanMaintain::Scenario
    metadata do
      description 'present_service pre_upgrade_checks scenario'
      tags :upgrade, :present_upgrade, :pre_upgrade_checks, :upgrade_scenario
      run_strategy :fail_slow

      confine do
        feature(:present_service)
      end
    end

    def target_version
      '1.15'
    end

    def compose
      add_steps(
        Checks::PresentServiceIsRunning,
        Checks::ServiceIsStopped,
        Procedures::PresentServiceRestart,
      )
    end
  end

  class PreMigrations < ForemanMaintain::Scenario
    metadata do
      description 'present_service pre_migrations scenario'
      tags :upgrade, :present_upgrade, :pre_migrations, :upgrade_scenario

      confine do
        feature(:present_service)
      end
    end

    def target_version
      '1.15'
    end

    def compose
      add_steps(
        Procedures::StopService,
        Procedures::Upgrade::PreMigration
      )
    end
  end

  class Migrations < ForemanMaintain::Scenario
    metadata do
      description 'present_service migrations scenario'
      tags :upgrade, :present_upgrade, :migrations, :upgrade_scenario

      confine do
        feature(:present_service)
      end
    end

    def target_version
      '1.15'
    end

    def compose
      add_steps(
        Procedures::Upgrade::Migration,
      )
    end
  end

  class PostMigrations < ForemanMaintain::Scenario
    metadata do
      description 'present_service post_migrations scenario'
      tags :upgrade, :present_upgrade, :post_migrations, :upgrade_scenario

      confine do
        feature(:present_service)
      end
    end

    def target_version
      '1.15'
    end

    def compose
      add_steps(
        Procedures::Upgrade::PostMigration,
      )
    end
  end

  class PostUpgradeChecks < ForemanMaintain::Scenario
    metadata do
      description 'present_service post_migrations scenario'
      tags :upgrade, :present_upgrade, :post_upgrade_checks, :upgrade_scenario

      confine do
        feature(:present_service)
      end
    end

    def target_version
      '1.15'
    end

    def compose
      add_steps(
        Procedures::Upgrade::PostUpgradeCheck,
      )
    end
  end
end
