module Scenarios::Foreman_Nightly
  class Abstract < ForemanMaintain::Scenario
    def self.upgrade_metadata(&block)
      metadata do
        tags :upgrade_scenario
        confine do
          feature(:foreman_install) || ForemanMaintain.upgrade_in_progress == 'nightly'
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
      description 'Checks before upgrading to Foreman nightly'
      tags :pre_upgrade_checks
      run_strategy :fail_slow
    end

    # rubocop:disable Metrics/MethodLength
    def compose
      add_steps(
        Checks::Foreman::FactsNames.new, # if Foreman database present
        Checks::ForemanProxy::CheckTftpStorage.new, # if Satellite with foreman-proxy+tftp
        Checks::ForemanProxy::VerifyDhcpConfigSyntax.new, # if foreman-proxy+dhcp-isc
        Checks::ForemanTasks::NotPaused.new, # if foreman-tasks present
        Checks::Puppet::VerifyNoEmptyCacertRequests.new, # if puppetserver
        Checks::ServerPing.new,
        Checks::ServicesUp.new
      )
      add_steps(
        Checks::CheckTmout.new,
        Checks::Disk::AvailableSpace.new,
        Checks::Foreman::ValidateExternalDbVersion.new, # if external database
        Checks::Foreman::CheckCorruptedRoles.new,
        Checks::Foreman::CheckDuplicatePermissions.new,
        Checks::ForemanOpenscap::InvalidReportAssociations.new, # if foreman-openscap
        Checks::ForemanTasks::Invalid::CheckOld.new, # if foreman-tasks
        Checks::ForemanTasks::Invalid::CheckPendingState.new, # if foreman-tasks
        Checks::ForemanTasks::Invalid::CheckPlanningState.new, # if foreman-tasks
        Checks::ForemanTasks::NotRunning.new, # if foreman-tasks
        Checks::PackageManager::Dnf::ValidateDnfConfig.new
      )
    end
    # rubocop:enable Metrics/MethodLength
  end

  class PreMigrations < Abstract
    upgrade_metadata do
      description 'Procedures before upgrading to Foreman nightly'
      tags :pre_migrations
    end

    def compose
      add_step(Procedures::MaintenanceMode::EnableMaintenanceMode.new)
      add_step(Procedures::Crond::Stop.new)
    end
  end

  class Migrations < Abstract
    upgrade_metadata do
      description 'Upgrade steps for Foreman nightly'
      tags :migrations
      run_strategy :fail_fast
    end

    def set_context_mapping
      context.map(:assumeyes, Procedures::Installer::Upgrade => :assumeyes)
    end

    def compose
      add_step(Procedures::Repositories::Setup.new(:version => 'nightly'))
      if el?
        modules_to_enable = ["foreman:#{el_short_name}"]
        add_step(Procedures::Packages::EnableModules.new(:module_names => modules_to_enable))
      end
      add_step(Procedures::Packages::Update.new(:assumeyes => true))
      add_step_with_context(Procedures::Installer::Upgrade)
    end
  end

  class PostMigrations < Abstract
    upgrade_metadata do
      description 'Post upgrade procedures for Foreman nightly'
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
      description 'Checks after upgrading to Foreman nightly'
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
        Checks::ServicesUp.new
      )
      add_step(Procedures::Packages::CheckForReboot)
    end
  end
end
