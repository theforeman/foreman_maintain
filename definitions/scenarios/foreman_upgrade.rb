module Scenarios::Foreman
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

    def target_version
      'nightly'
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
        Checks::Disk::AvailableSpacePostgresql13,
        Checks::Disk::PostgresqlMountpoint,
        Checks::Foreman::ValidateExternalDbVersion, # if external database
        Checks::Foreman::CheckExternalDbEvrPermissions, # if external database
        Checks::Foreman::CheckCorruptedRoles,
        Checks::Foreman::CheckDuplicatePermissions,
        Checks::Foreman::TuningRequirements, # if katello present
        Checks::ForemanOpenscap::InvalidReportAssociations, # if foreman-openscap
        Checks::ForemanTasks::Invalid::CheckOld, # if foreman-tasks
        Checks::ForemanTasks::Invalid::CheckPendingState, # if foreman-tasks
        Checks::ForemanTasks::Invalid::CheckPlanningState, # if foreman-tasks
        Checks::ForemanTasks::NotRunning, # if foreman-tasks
        Checks::Pulpcore::NoRunningTasks, # if pulpcore
        Checks::NonRhPackages,
        Checks::PackageManager::Dnf::ValidateDnfConfig,
        Checks::Repositories::CheckNonRhRepository,
        Checks::CheckOrganizationContentAccessMode,
        Checks::CheckSha1CertificateAuthority,
        Checks::Repositories::Validate
      )
    end
    # rubocop:enable Metrics/MethodLength
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description 'Procedures before upgrading'
      tags :pre_migrations
    end

    def compose
      add_steps(
        Procedures::Repositories::CleanupDuplicateErratumPackages,
        Procedures::MaintenanceMode::EnableMaintenanceMode,
        Procedures::Crond::Stop,
        Procedures::Timer::Stop,
        Procedures::SyncPlans::Disable
      )
    end
  end

  class Migrations < Abstract
    upgrade_metadata do
      description 'Upgrade steps'
      tags :migrations
      run_strategy :fail_fast
    end

    def set_context_mapping
      context.map(:assumeyes, Procedures::Installer::Run => :assumeyes)
    end

    def compose
      add_step(Procedures::Repositories::Setup.new(:version => 'nightly'))

      add_step(Procedures::Packages::Update.new(
        :assumeyes => true,
        :download_only => true
      ))
      add_step(Procedures::Service::Stop.new)
      add_step(Procedures::Packages::Update.new(:assumeyes => true, :clean_cache => false))

      add_step_with_context(Procedures::Installer::Run)
    end
  end

  class PostMigrations < Abstract
    upgrade_metadata do
      description 'Post upgrade procedures'
      tags :post_migrations
    end

    def compose
      add_steps(
        Procedures::RefreshFeatures,
        Procedures::Service::Start,
        Procedures::Crond::Start,
        Procedures::Timer::Start,
        Procedures::SyncPlans::Enable,
        Procedures::MaintenanceMode::DisableMaintenanceMode
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
        Procedures::Repositories::IndexKatelloRepositoriesContainerMetatdata
      )
    end
  end
end
