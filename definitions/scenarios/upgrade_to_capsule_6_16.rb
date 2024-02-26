module Scenarios::Capsule_6_16
  class Abstract < ForemanMaintain::Scenario
    def self.upgrade_metadata(&block)
      metadata do
        tags :upgrade_scenario
        confine do
          feature(:capsule) &&
            (feature(:capsule).current_minor_version == '6.15' || \
            ForemanMaintain.upgrade_in_progress == '6.16')
        end
        instance_eval(&block)
      end
    end

    def target_version
      '6.16'
    end
  end

  class PreUpgradeCheck < Abstract
    upgrade_metadata do
      description 'Checks before upgrading to Capsule 6.16'
      tags :pre_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:pre_upgrade))
      add_step(Checks::Disk::AvailableSpacePostgresql13)
      add_step(Checks::Repositories::Validate.new(:version => '6.16'))
    end
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description 'Procedures before migrating to Capsule 6.16'
      tags :pre_migrations
    end

    def compose
      add_step(Procedures::Repositories::Setup.new(:version => '6.16'))
      if el8?
        modules_to_enable = ["satellite-capsule:#{el_short_name}"]
        add_step(Procedures::Packages::EnableModules.new(:module_names => modules_to_enable))
      end
      add_step(Procedures::Packages::Update.new(
        :assumeyes => true,
        :dnf_options => ['--downloadonly']
      ))

      add_steps(find_procedures(:pre_migrations))
    end
  end

  class Migrations < Abstract
    upgrade_metadata do
      description 'Migration scripts to Capsule 6.16'
      tags :migrations
    end

    def set_context_mapping
      context.map(:assumeyes, Procedures::Installer::Run => :assumeyes)
    end

    def compose
      add_step(Procedures::Service::Stop.new)
      add_step(Procedures::Packages::Update.new(:assumeyes => true, :clean_cache => false))
      add_step_with_context(Procedures::Installer::Run)
    end
  end

  class PostMigrations < Abstract
    upgrade_metadata do
      description 'Procedures after migrating to Capsule 6.16'
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
      description 'Checks after upgrading to Capsule 6.16'
      tags :post_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:post_upgrade))
      add_step(Procedures::Packages::CheckForReboot)
    end
  end
end
