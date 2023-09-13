module Scenarios::Satellite_6_15_z
  class Abstract < ForemanMaintain::Scenario
    def self.upgrade_metadata(&block)
      metadata do
        tags :upgrade_scenario
        confine do
          feature(:satellite) &&
            (feature(:satellite).current_minor_version == '6.15' || \
            ForemanMaintain.upgrade_in_progress == '6.15.z')
        end
        instance_eval(&block)
      end
    end

    def target_version
      '6.15.z'
    end
  end

  class PreUpgradeCheck < Abstract
    upgrade_metadata do
      description 'Checks before upgrading to Satellite 6.15.z'
      tags :pre_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:pre_upgrade))
      add_step(Checks::Repositories::Validate.new(:version => '6.15'))
    end
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description 'Procedures before migrating to Satellite 6.15.z'
      tags :pre_migrations
    end

    def compose
      add_steps(find_procedures(:pre_migrations))
    end
  end

  class Migrations < Abstract
    upgrade_metadata do
      description 'Migration scripts to Satellite 6.15.z'
      tags :migrations
    end

    def set_context_mapping
      context.map(:assumeyes, Procedures::Installer::Upgrade => :assumeyes)
    end

    def compose
      add_step(Procedures::Repositories::Setup.new(:version => '6.15'))
      modules_to_enable = ["satellite:#{el_short_name}"]
      add_step(Procedures::Packages::EnableModules.new(:module_names => modules_to_enable))
      add_step(Procedures::Packages::Update.new(:assumeyes => true,
        :dnf_options => ['--downloadonly']))
      add_step(Procedures::Service::Stop.new)
      add_step(Procedures::Packages::Update.new(:assumeyes => true))
      add_step_with_context(Procedures::Installer::Upgrade)
      add_step(Procedures::Installer::UpgradeRakeTask)
    end
  end

  class PostMigrations < Abstract
    upgrade_metadata do
      description 'Procedures after migrating to Satellite 6.15.z'
      tags :post_migrations
    end

    def compose
      add_step(Procedures::RefreshFeatures)
      add_step(Procedures::Service::Start.new)
      add_steps(find_procedures(:post_migrations))
    end
  end

  class PostUpgradeChecks < Abstract
    upgrade_metadata do
      description 'Checks after upgrading to Satellite 6.15.z'
      tags :post_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:post_upgrade))
    end
  end
end
