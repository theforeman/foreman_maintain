module Scenarios::Foreman_1_24
  class Abstract < ForemanMaintain::Scenario
    def self.upgrade_metadata(&block)
      metadata do
        tags :upgrade_scenario
        confine do
          feature(:instance).upstream? && feature(:foreman_server) && \
            (feature(:foreman_server).current_version.major_minor == '1.23' || \
                ForemanMaintain.upgrade_in_progress == '1.24') && !feature(:katello)
        end
        instance_eval(&block)
      end
    end

    def target_version
      '1.24'
    end
  end

  class PreUpgradeCheck < Abstract
    upgrade_metadata do
      description 'Checks before upgrading to Foreman 1.24'
      tags :pre_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:pre_upgrade))
      add_step(Checks::Repositories::Validate.new(:version => '1.24'))
    end
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description 'Procedures before migrating to Foreman 1.24'
      tags :pre_migrations
    end

    def compose
      add_steps(find_procedures(:pre_migrations))
      add_step(Procedures::Service::Stop.new)
    end
  end

  class Migrations < Abstract
    upgrade_metadata do
      description 'Migration scripts to Foreman 1.24'
      tags :migrations
    end

    def compose
      add_step(Procedures::Repositories::Setup.new(:version => '1.24'))
      add_step(Procedures::Packages::UnlockVersions.new)
      add_step(Procedures::Packages::UpdateCollections.new(:assumeyes => true))
      add_step(Procedures::Packages::Update.new(:assumeyes => true))
      add_step(Procedures::Installer::Upgrade.new)
    end
  end

  class PostMigrations < Abstract
    upgrade_metadata do
      description 'Procedures after migrating to Foreman 1.24'
      tags :post_migrations
    end

    def compose
      add_step(Procedures::Foreman::ClearCache.new)
      add_step(Procedures::Foreman::ClearSessions.new)
      add_step(Procedures::Foreman::ApipieCache.new)
      add_step(Procedures::Service::Stop.new(:exclude => 'postgresql'))
      add_step(Procedures::Foreman::VacuumDatabase.new)
      add_step(Procedures::Service::Start.new)
      add_step(Procedures::Packages::CleanupCollections.new(
                 :packages => %w[rhscl-\* rh-ruby22\* rh-ror42\*]
      ))
      add_steps(find_procedures(:post_migrations))
    end
  end

  class PostUpgradeChecks < Abstract
    upgrade_metadata do
      description 'Checks after upgrading to Foreman 1.24'
      tags :post_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:post_upgrade))
      add_step(Checks::Foreman::CheckForMysql.new)
    end
  end
end
