module Scenarios::ForemanUpgrade
  class Abstract < ForemanMaintain::Scenario
    def self.upgrade_metadata(&block)
      metadata do
        tags :upgrade_scenario
        confine do
          feature(:foreman_install)
        end
        instance_eval(&block)
      end
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
    end
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description 'Procedures before upgrading'
      tags :pre_migrations
    end

    def compose
      add_steps(find_procedures(:pre_migrations))
    end
  end

  class Migrations < Abstract
    upgrade_metadata do
      description 'Upgrade steps'
      tags :migrations
      run_strategy :fail_fast
    end

    def set_context_mapping
      context.map(:assumeyes, Procedures::Installer::Upgrade => :assumeyes)
    end

    def compose
      add_step(Procedures::Service::Stop.new)

      if el?
        modules_to_enable = ["foreman:#{el_short_name}"]

        if feature(:katello)
          modules_to_enable.append(
            "katello:#{el_short_name}",
            "pulpcore:#{el_short_name}"
          )
        end

        add_step(Procedures::Packages::EnableModules.new(:module_names => modules_to_enable))
        add_step(Procedures::Packages::Update.new(
          :assumeyes => true,
          :dnf_options => ['--downloadonly']
        ))
        add_step(Procedures::Packages::Update.new(:assumeyes => true, :clean_cache => false))
      else
        add_step(Procedures::Packages::Update.new(:assumeyes => true))
      end

      add_step_with_context(Procedures::Installer::Upgrade)
    end
  end

  class PostMigrations < Abstract
    upgrade_metadata do
      description 'Post upgrade procedures'
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
    end
  end
end
