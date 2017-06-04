module Scenarios::PresentUpgrade
  class PreUpgradeChecks < ForemanMaintain::Scenario
    metadata do
      description 'present_service pre_upgrade_checks scenario'
      tags :upgrade, :present_upgrade, :pre_upgrade_checks
      run_strategy :fail_slow

      confine do
        feature(:present_service)
      end
    end

    def compose
      add_steps(find_checks(:default))
      add_step(procedure(Procedures::PresentServiceRestart))
    end
  end

  class PreMigrations < ForemanMaintain::Scenario
    metadata do
      description 'present_service pre_migrations scenario'
      tags :upgrade, :present_upgrade, :pre_migrations

      confine do
        feature(:present_service)
      end
    end

    def compose
      add_steps(find_procedures(:pre_migrations))
    end
  end
end

ForemanMaintain::UpgradeRunner.register_version('1.15', :present_upgrade)
