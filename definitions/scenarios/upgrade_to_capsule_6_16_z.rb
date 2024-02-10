module Scenarios::Capsule_6_16_z
  class Abstract < ForemanMaintain::Scenario
    def self.upgrade_metadata(&block)
      metadata do
        tags :upgrade_scenario
        confine do
          feature(:capsule) &&
            (feature(:capsule).current_minor_version == '6.16' || \
              ForemanMaintain.upgrade_in_progress == '6.16.z')
        end
        instance_eval(&block)
      end
    end

    def target_version
      '6.16.z'
    end
  end

  class PreUpgradeCheck < Abstract
    upgrade_metadata do
      description 'Checks before upgrading to Capsule 6.16.z'
      tags :pre_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(
        Checks::ForemanProxy::VerifyDhcpConfigSyntax.new, # if foreman-proxy+dhcp-isc
        Checks::Puppet::VerifyNoEmptyCacertRequests.new, # if puppetserver
        Checks::ServerPing.new,
        Checks::ServicesUp.new,
        Checks::SystemRegistration.new
      )
      add_steps(
        Checks::CheckHotfixInstalled.new,
        Checks::CheckTmout.new,
        Checks::CheckUpstreamRepository.new,
        Checks::Disk::AvailableSpace.new,
        Checks::NonRhPackages.new,
        Checks::PackageManager::Dnf::ValidateDnfConfig.new,
        Checks::Repositories::CheckNonRhRepository.new
      )
      add_step(Checks::Repositories::Validate.new(:version => '6.16'))
    end
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description 'Procedures before migrating to Capsule 6.16.z'
      tags :pre_migrations
    end

    def compose
      add_step(Procedures::Repositories::Setup.new(:version => '6.16'))
      modules_to_enable = ["satellite-capsule:#{el_short_name}"]
      add_step(Procedures::Packages::EnableModules.new(:module_names => modules_to_enable))
      add_step(Procedures::Packages::Update.new(
        :assumeyes => true,
        :dnf_options => ['--downloadonly']
      ))
      add_step(Procedures::MaintenanceMode::EnableMaintenanceMode.new)
      add_step(Procedures::Crond::Stop.new)
    end
  end

  class Migrations < Abstract
    upgrade_metadata do
      description 'Migration scripts to Capsule 6.16.z'
      tags :migrations
    end

    def set_context_mapping
      context.map(:assumeyes, Procedures::Installer::Upgrade => :assumeyes)
    end

    def compose
      add_step(Procedures::Service::Stop.new)
      add_step(Procedures::Packages::Update.new(:assumeyes => true, :clean_cache => false))
      add_step_with_context(Procedures::Installer::Upgrade)
    end
  end

  class PostMigrations < Abstract
    upgrade_metadata do
      description 'Procedures after migrating to Capsule 6.16.z'
      tags :post_migrations
    end

    def compose
      add_step(Procedures::RefreshFeatures.new)
      add_step(Procedures::Service::Start.new)
      add_step(Procedures::Crond::Start.new)
      add_step(Procedures::MaintenanceMode::DisableMaintenanceMode.new)
    end
  end

  class PostUpgradeChecks < Abstract
    upgrade_metadata do
      description 'Checks after upgrading to Capsule 6.16.z'
      tags :post_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(
        Checks::ForemanProxy::VerifyDhcpConfigSyntax.new, # if foreman-proxy+dhcp-isc
        Checks::Puppet::VerifyNoEmptyCacertRequests.new, # if puppetserver
        Checks::ServerPing.new,
        Checks::ServicesUp.new,
        Checks::SystemRegistration.new
      )
      add_step(Procedures::Packages::CheckForReboot)
    end
  end
end
