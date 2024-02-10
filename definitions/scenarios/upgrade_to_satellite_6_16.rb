module Scenarios::Satellite_6_16
  class Abstract < ForemanMaintain::Scenario
    def self.upgrade_metadata(&block)
      metadata do
        tags :upgrade_scenario
        confine do
          feature(:satellite) &&
            (feature(:satellite).current_minor_version == '6.15' || \
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
      description 'Checks before upgrading to Satellite 6.16'
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
      add_step(Checks::Repositories::Validate.new(:version => '6.16'))
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description 'Procedures before migrating to Satellite 6.16'
      tags :pre_migrations
    end

    def compose
      add_step(Procedures::Repositories::Setup.new(:version => '6.16'))
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
      description 'Migration scripts to Satellite 6.16'
      tags :migrations
      run_strategy :fail_fast
    end

    def set_context_mapping
      context.map(:assumeyes, Procedures::Installer::Upgrade => :assumeyes)
    end

    def compose
      add_step(Procedures::Service::Stop.new)
      add_step(Procedures::Packages::Update.new(:assumeyes => true, :clean_cache => false))
      add_step_with_context(Procedures::Installer::Upgrade)
      add_step(Procedures::Installer::UpgradeRakeTask)
    end
  end

  class PostMigrations < Abstract
    upgrade_metadata do
      description 'Procedures after migrating to Satellite 6.16'
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
      description 'Checks after upgrading to Satellite 6.16'
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
    end
  end
end
