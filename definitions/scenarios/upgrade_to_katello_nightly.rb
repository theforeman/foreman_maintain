module Scenarios::Katello_Nightly
  class Abstract < ForemanMaintain::Scenario
    def self.target_version
      'nightly'
    end

    def self.upgrade_metadata(&block)
      target_version = self.target_version

      metadata do
        tags :upgrade_scenario
        confine do
          feature(:katello_install) || ForemanMaintain.upgrade_in_progress == target_version
        end

        @target_version = target_version
        def target_version
          @target_version
        end

        def target
          "Katello #{target_version}"
        end

        instance_eval(&block)
      end
    end

    def target_version
      self.target_version
    end
  end

  class PreUpgradeCheck < Abstract
    upgrade_metadata do
      description "Checks before upgrading to #{target}"
      tags :pre_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:pre_upgrade))
    end
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description "Procedures before upgrading to #{target}"
      tags :pre_migrations
    end

    def compose
      add_steps(find_procedures(:pre_migrations))
    end
  end

  class Migrations < Abstract
    upgrade_metadata do
      description "Upgrade steps for #{target}"
      tags :migrations
      run_strategy :fail_fast
    end

    def set_context_mapping
      context.map(:assumeyes, Procedures::Installer::Upgrade => :assumeyes)
    end

    def compose
      add_step(Procedures::Repositories::Setup.new(:version => target_version))
      modules_to_enable = ["katello:#{el_short_name}", "pulpcore:#{el_short_name}"]
      add_step(Procedures::Packages::EnableModules.new(:module_names => modules_to_enable))
      add_step(Procedures::Packages::Update.new(:assumeyes => true))
      add_step_with_context(Procedures::Installer::Upgrade)
    end
  end

  class PostMigrations < Abstract
    upgrade_metadata do
      description "Post upgrade procedures for #{target}"
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
      description "Checks after upgrading to #{target}"
      tags :post_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(find_checks(:default))
      add_steps(find_checks(:post_upgrade))
    end
  end
end
