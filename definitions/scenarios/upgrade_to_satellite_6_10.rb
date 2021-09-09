module Scenarios::Satellite_6_10
  class Abstract < ForemanMaintain::Scenario
    def self.upgrade_metadata(&block)
      metadata do
        tags :upgrade_scenario
        confine do
          feature(:satellite) &&
            (feature(:satellite).current_minor_version == '6.9' || \
            ForemanMaintain.upgrade_in_progress == '6.10')
        end
        instance_eval(&block)
      end
    end

    def target_version
      '6.10'
    end
  end

  class PreUpgradeCheck < Abstract
    upgrade_metadata do
      description 'Checks before upgrading to Satellite 6.10'
      tags :pre_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_step(Checks::Puppet::WarnAboutPuppetRemoval)
      add_steps(find_checks(:default))
      add_steps(find_checks(:pre_upgrade))
      add_step(Checks::Foreman::CheckpointSegments)
      add_step(Checks::Repositories::Validate.new(:version => '6.10'))
    end
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description 'Procedures before migrating to Satellite 6.10'
      tags :pre_migrations
    end

    def compose
      add_steps(find_procedures(:pre_migrations))
      add_step(Procedures::Service::Stop.new)
    end
  end

  class Migrations < Abstract
    upgrade_metadata do
      description 'Migration scripts to Satellite 6.10'
      tags :migrations
      run_strategy :fail_fast
    end

    def set_context_mapping
      context.map(:assumeyes, Procedures::Installer::Upgrade => :assumeyes)
    end

    def check_var_lib_pulp
      group_id = File.stat('/var/lib/pulp/').gid
      if Etc.getgrgid(group_id).name != 'pulp'
        raise "Please run 'foreman-maintain prep-6.10-upgrade' prior to upgrading."
      end
    end

    def pulp3_switchover_steps
      add_step(Procedures::Service::Enable.
          new(:only => Features::Pulpcore.pulpcore_migration_services))
      add_step(Procedures::RefreshFeatures)
      add_step(Procedures::Service::Start)
      add_step(Procedures::Content::Switchover.new)
      add_step(Procedures::Service::Stop.
                 new(:only => Features::Pulpcore.pulpcore_migration_services))
    end

    def compose
      check_var_lib_pulp
      unless check_min_version(foreman_plugin_name('katello'), '4.0')
        pulp3_switchover_steps
      end
      add_step(Procedures::Repositories::Setup.new(:version => '6.10'))
      add_step(Procedures::Packages::UnlockVersions.new)
      add_step(Procedures::Packages::Update.new(:assumeyes => true))
      add_step_with_context(Procedures::Installer::Upgrade)
      add_step(Procedures::Installer::UpgradeRakeTask)
    end
  end

  class PostMigrations < Abstract
    upgrade_metadata do
      description 'Procedures after migrating to Satellite 6.10'
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
      description 'Checks after upgrading to Satellite 6.10'
      tags :post_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:post_upgrade))
      add_step(Procedures::Pulp::PrintRemoveInstructions.new)
    end
  end
end
