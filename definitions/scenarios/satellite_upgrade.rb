module Scenarios::Satellite
  class Abstract < ForemanMaintain::Scenario
    def self.upgrade_metadata(&block)
      metadata do
        tags :upgrade_scenario
        confine do
          (feature(:downstream).current_minor_version == '6.15' || \
            ForemanMaintain.upgrade_in_progress == target_version)
        end
        instance_eval(&block)
      end
    end

    def target_version
      feature(:instance).target_version
    end
  end

  class PreUpgradeCheck < Abstract
    upgrade_metadata do
      description 'Checks before upgrading'
      tags :pre_upgrade_checks
      run_strategy :fail_slow
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def compose
      add_steps(
        Checks::Foreman::FactsNames.new, # if Foreman database present
        Checks::ForemanProxy::CheckTftpStorage.new, # if Satellite with foreman-proxy+tftp
        Checks::ForemanProxy::VerifyDhcpConfigSyntax.new, # if foreman-proxy+dhcp-isc
        Checks::ForemanTasks::NotPaused.new, # if foreman-tasks present
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
        Checks::Disk::AvailableSpaceCandlepin.new, # if candlepin
        Checks::Foreman::ValidateExternalDbVersion.new, # if external database
        Checks::Foreman::CheckCorruptedRoles.new,
        Checks::Foreman::CheckDuplicatePermissions.new,
        Checks::Foreman::TuningRequirements.new, # if katello present
        Checks::ForemanOpenscap::InvalidReportAssociations.new, # if foreman-openscap
        Checks::ForemanTasks::Invalid::CheckOld.new, # if foreman-tasks
        Checks::ForemanTasks::Invalid::CheckPendingState.new, # if foreman-tasks
        Checks::ForemanTasks::Invalid::CheckPlanningState.new, # if foreman-tasks
        Checks::ForemanTasks::NotRunning.new, # if foreman-tasks
        Checks::NonRhPackages.new,
        Checks::PackageManager::Dnf::ValidateDnfConfig.new,
        Checks::Repositories::CheckNonRhRepository.new
      )
      add_step(Checks::CheckIpv6Disable)
      add_step(Checks::Disk::AvailableSpacePostgresql13)
      add_step(Checks::Repositories::Validate.new(:version => target_version))
      add_step(Checks::CheckOrganizationContentAccessMode)
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description 'Procedures before migrating'
      tags :pre_migrations
    end

    def compose
      add_step(Procedures::Repositories::Setup.new(:version => target_version))
      modules_to_enable = ["satellite:#{el_short_name}"]
      add_step(Procedures::Packages::EnableModules.new(:module_names => modules_to_enable))
      add_step(Procedures::Packages::Update.new(
        :assumeyes => true,
        :dnf_options => ['--downloadonly']
      ))
      add_step(Procedures::MaintenanceMode::EnableMaintenanceMode.new)
      add_step(Procedures::Crond::Stop.new)
      add_step(Procedures::SyncPlans::Disable.new)
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
        modules_to_enable = ["satellite:#{el_short_name}"]
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
      add_step(Procedures::RefreshFeatures.new)
      add_step(Procedures::Service::Start.new)
      add_step(Procedures::Crond::Start.new)
      add_step(Procedures::SyncPlans::Enable.new)
      add_step(Procedures::MaintenanceMode::DisableMaintenanceMode.new)
    end
  end

  class PostUpgradeChecks < Abstract
    upgrade_metadata do
      description 'Checks after upgrading'
      tags :post_upgrade_checks
      run_strategy :fail_slow
    end

    def compose
      add_steps(
        Checks::Foreman::FactsNames.new, # if Foreman database present
        Checks::ForemanProxy::CheckTftpStorage.new, # if Satellite with foreman-proxy+tftp
        Checks::ForemanProxy::VerifyDhcpConfigSyntax.new, # if foreman-proxy+dhcp-isc
        Checks::ForemanTasks::NotPaused.new, # if foreman-tasks present
        Checks::Puppet::VerifyNoEmptyCacertRequests.new, # if puppetserver
        Checks::ServerPing.new,
        Checks::ServicesUp.new,
        Checks::SystemRegistration.new
      )
      add_step(Procedures::Packages::CheckForReboot)
      add_step(Procedures::Pulpcore::ContainerHandleImageMetadata)
    end
  end
end
