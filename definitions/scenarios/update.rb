module Scenarios::Update
  class Abstract < ForemanMaintain::Scenario
    def self.update_metadata(&block)
      metadata do
        tags :update_scenario

        confine do
          feature(:instance).target_version == feature(:instance).current_major_version
        end

        instance_eval(&block)
      end
    end
  end

  class PreUpdateCheck < Abstract
    update_metadata do
      description 'Checks before updating'
      tags :pre_update_checks
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
        Checks::CheckIpv6Disable,
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
        Checks::Pulpcore::NoRunningTasks, # if pulpcore
        Checks::NonRhPackages,
        Checks::PackageManager::Dnf::ValidateDnfConfig,
        Checks::Repositories::CheckNonRhRepository,
        Checks::Repositories::Validate
      )
    end
    # rubocop:enable Metrics/MethodLength
  end

  class PreMigrations < Abstract
    update_metadata do
      description 'Procedures before migrating'
      tags :pre_migrations
    end

    def compose
      add_steps(
        Procedures::Packages::Update.new(
          :assumeyes => true,
          :download_only => true
        ),
        Procedures::MaintenanceMode::EnableMaintenanceMode,
        Procedures::Crond::Stop,
        Procedures::SyncPlans::Disable
      )
    end
  end

  class Migrations < Abstract
    update_metadata do
      description 'Migration scripts'
      tags :migrations
      run_strategy :fail_fast
    end

    def compose
      add_steps(
        Procedures::Service::Stop,
        Procedures::Packages::Update.new(:assumeyes => true, :clean_cache => false),
        Procedures::Installer::Run.new(:assumeyes => true),
        Procedures::Installer::UpgradeRakeTask
      )
    end
  end

  class PostMigrations < Abstract
    update_metadata do
      description 'Procedures after migrating'
      tags :post_migrations
    end

    def compose
      add_steps(
        Procedures::RefreshFeatures,
        Procedures::Service::Start,
        Procedures::Crond::Start,
        Procedures::SyncPlans::Enable,
        Procedures::MaintenanceMode::DisableMaintenanceMode
      )
    end
  end

  class PostUpdateChecks < Abstract
    update_metadata do
      description 'Checks after update'
      tags :post_update_checks
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
        Procedures::Packages::CheckForReboot
      )
    end
  end
end
