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

    # rubocop:disable Metrics/MethodLength
    def compose
      add_steps(
        Checks::Foreman::FactsNames, # if Foreman database present
        Checks::ForemanProxy::CheckTftpStorage, # if Satellite with foreman-proxy+tftp
        Checks::ForemanProxy::VerifyDhcpConfigSyntax, # if foreman-proxy+dhcp-isc
        Checks::ForemanTasks::NotPaused, # if foreman-tasks present
        Checks::Puppet::VerifyNoEmptyCacertRequests, # if puppetserver
        Checks::ServerPing,
        Checks::ServicesUp,
        Checks::SystemRegistration,
        Checks::CheckHotfixInstalled,
        Checks::CheckTmout,
        Checks::CheckUpstreamRepository,
        Checks::Disk::AvailableSpace,
        Checks::Disk::AvailableSpaceCandlepin, # if candlepin
        Checks::Foreman::ValidateExternalDbVersion, # if external database
        Checks::Foreman::CheckCorruptedRoles,
        Checks::Foreman::CheckDuplicatePermissions,
        Checks::Foreman::TuningRequirements, # if katello present
        Checks::ForemanOpenscap::InvalidReportAssociations, # if foreman-openscap
        Checks::ForemanTasks::Invalid::CheckOld, # if foreman-tasks
        Checks::ForemanTasks::Invalid::CheckPendingState, # if foreman-tasks
        Checks::ForemanTasks::Invalid::CheckPlanningState, # if foreman-tasks
        Checks::ForemanTasks::NotRunning, # if foreman-tasks
        Checks::NonRhPackages,
        Checks::PackageManager::Dnf::ValidateDnfConfig,
        Checks::Repositories::CheckNonRhRepository,
        Checks::CheckIpv6Disable,
        Checks::Disk::AvailableSpacePostgresql13,
        Checks::CheckOrganizationContentAccessMode,
        Checks::Repositories::Validate.new(:version => target_version),
      )
    end
    # rubocop:enable Metrics/MethodLength
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description 'Procedures before migrating'
      tags :pre_migrations
    end

    def compose
      add_steps(
        Procedures::MaintenanceMode::EnableMaintenanceMode,
        Procedures::Crond::Stop,
        Procedures::SyncPlans::Disable,
      )
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
      add_steps(
        Procedures::Packages::Update.new(
          :assumeyes => true,
          :download_only => true
        ),
        Procedures::Service::Stop,
        Procedures::Packages::Update.new(:assumeyes => true, :clean_cache => false),
      )
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
      add_steps(
        Procedures::RefreshFeatures,
        Procedures::Service::Start,
        Procedures::Crond::Start,
        Procedures::SyncPlans::Enable,
        Procedures::MaintenanceMode::DisableMaintenanceMode,
      )
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
        Checks::Foreman::FactsNames, # if Foreman database present
        Checks::ForemanProxy::CheckTftpStorage, # if Satellite with foreman-proxy+tftp
        Checks::ForemanProxy::VerifyDhcpConfigSyntax, # if foreman-proxy+dhcp-isc
        Checks::ForemanTasks::NotPaused, # if foreman-tasks present
        Checks::Puppet::VerifyNoEmptyCacertRequests, # if puppetserver
        Checks::ServerPing,
        Checks::ServicesUp,
        Checks::SystemRegistration,
        Procedures::Packages::CheckForReboot,
        Procedures::Pulpcore::ContainerHandleImageMetadata,
        Procedures::Repositories::IndexKatelloRepositoriesContainerMetatdata,
      )
    end
  end
end
