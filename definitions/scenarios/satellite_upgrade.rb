module Scenarios::Satellite
  class Abstract < ForemanMaintain::Scenario
    def self.upgrade_metadata(&block)
      metadata do
        tags :upgrade_scenario
        confine do
          (feature(:instance).downstream&.current_minor_version == '6.15' || \
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
      description 'Checks before upgrading'
      tags :pre_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:pre_upgrade))
      add_step(Checks::CheckIpv6Disable)
      add_step(Checks::Disk::AvailableSpacePostgresql13)
      add_step(Checks::Repositories::Validate.new(:version => target_version))
      add_step(Checks::CheckOrganizationContentAccessMode)
    end
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description 'Procedures before migrating'
      tags :pre_migrations
    end

    def compose
      add_steps(find_procedures(:pre_migrations))
    end
  end

  class Migrations < Abstract
    upgrade_metadata do
      description 'Migration scripts'
      tags :migrations
      run_strategy :fail_fast
    end

    def set_context_mapping
      context.map(:assumeyes, Procedures::Installer::Run => :assumeyes)
    end

    def compose
      add_step(Procedures::Repositories::Setup.new(:version => target_version))
      if el8?
        modules_to_switch = ['postgresql:13']
        add_step(Procedures::Packages::SwitchModules.new(:module_names => modules_to_switch))
        modules_to_enable = ["#{feature(:instance).downstream.module_name}:#{el_short_name}"]
        add_step(Procedures::Packages::EnableModules.new(:module_names => modules_to_enable))
      end
      add_step(Procedures::Packages::Update.new(
        :assumeyes => true,
        :download_only => true
      ))
      add_step(Procedures::Service::Stop.new)
      add_step(Procedures::Packages::Update.new(:assumeyes => true, :clean_cache => false))
      add_step_with_context(Procedures::Installer::Run)
      add_step(Procedures::Installer::UpgradeRakeTask)
    end
  end

  class PostMigrations < Abstract
    upgrade_metadata do
      description 'Procedures after migrating'
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
      description 'Checks after upgrading'
      tags :post_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:post_upgrade))
      add_step(Procedures::Packages::CheckForReboot)
      add_step(Procedures::Pulpcore::ContainerHandleImageMetadata)
      add_step(Procedures::Repositories::IndexKatelloRepositoriesContainerMetatdata)
    end
  end
end
