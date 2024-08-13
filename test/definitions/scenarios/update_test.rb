require 'test_helper'

describe "update scenarios" do
  include DefinitionsTestHelper

  it 'runs if versions match' do
    assume_satellite_present
    Features::Instance.any_instance.expects(:current_version).returns('6.16')

    assert Scenarios::Update::PreUpdateCheck.present?
  end

  it 'does not run if versions mis-match' do
    assume_satellite_present
    Features::Instance.any_instance.expects(:current_version).returns('6.17')

    refute Scenarios::Update::PreUpdateCheck.present?
  end

  context 'Satellite update' do
    before(:each) do
      assume_satellite_present
      ForemanMaintain.config.stubs(:manage_crond).returns(true)
    end

    describe Scenarios::Update::PreUpdateCheck do
      let(:scenario) do
        Scenarios::Update::PreUpdateCheck.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::PreUpdateCheck.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Checks::Foreman::FactsNames,
          Checks::ForemanTasks::NotPaused,
          Checks::ServerPing,
          Checks::ServicesUp,
          Checks::SystemRegistration,
          Checks::CheckHotfixInstalled,
          Checks::CheckTmout,
          Checks::CheckUpstreamRepository,
          Checks::Disk::AvailableSpace,
          Checks::Disk::AvailableSpaceCandlepin,
          Checks::Foreman::CheckCorruptedRoles,
          Checks::Foreman::CheckDuplicatePermissions,
          Checks::Foreman::TuningRequirements,
          Checks::ForemanTasks::Invalid::CheckOld,
          Checks::ForemanTasks::Invalid::CheckPendingState,
          Checks::ForemanTasks::Invalid::CheckPlanningState,
          Checks::ForemanTasks::NotRunning,
          Checks::NonRhPackages,
          Checks::PackageManager::Dnf::ValidateDnfConfig,
          Checks::Repositories::CheckNonRhRepository,
          Checks::CheckIpv6Disable,
          Checks::Repositories::Validate,
          Checks::Pulpcore::NoRunningTasks,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::PreUpdateCheck.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Checks::Foreman::FactsNames,
          Checks::ForemanTasks::NotPaused,
          Checks::ServerPing,
          Checks::ServicesUp,
          Checks::SystemRegistration,
          Checks::CheckHotfixInstalled,
          Checks::CheckTmout,
          Checks::CheckUpstreamRepository,
          Checks::Disk::AvailableSpace,
          Checks::Disk::AvailableSpaceCandlepin,
          Checks::Foreman::CheckCorruptedRoles,
          Checks::Foreman::CheckDuplicatePermissions,
          Checks::Foreman::TuningRequirements,
          Checks::ForemanTasks::Invalid::CheckOld,
          Checks::ForemanTasks::Invalid::CheckPendingState,
          Checks::ForemanTasks::Invalid::CheckPlanningState,
          Checks::ForemanTasks::NotRunning,
          Checks::NonRhPackages,
          Checks::PackageManager::Dnf::ValidateDnfConfig,
          Checks::Repositories::CheckNonRhRepository,
          Checks::CheckIpv6Disable,
          Checks::Repositories::Validate,
          Checks::Pulpcore::NoRunningTasks,
        )
      end
    end

    describe Scenarios::Update::PreMigrations do
      let(:scenario) do
        Scenarios::Update::PreMigrations.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::PreMigrations.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Procedures::Packages::Update,
          Procedures::MaintenanceMode::EnableMaintenanceMode,
          Procedures::Crond::Stop,
          Procedures::SyncPlans::Disable,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::PreMigrations.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Procedures::Packages::Update,
          Procedures::MaintenanceMode::EnableMaintenanceMode,
          Procedures::Crond::Stop,
          Procedures::SyncPlans::Disable,
        )
      end
    end

    describe Scenarios::Update::Migrations do
      let(:scenario) do
        Scenarios::Update::Migrations.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::Migrations.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Procedures::Service::Stop,
          Procedures::Packages::Update,
          Procedures::Installer::Run,
          Procedures::Installer::UpgradeRakeTask,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::Migrations.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Procedures::Service::Stop,
          Procedures::Packages::Update,
          Procedures::Installer::Run,
          Procedures::Installer::UpgradeRakeTask,
        )
      end
    end

    describe Scenarios::Update::PostMigrations do
      let(:scenario) do
        Scenarios::Update::PostMigrations.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::PostMigrations.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Procedures::RefreshFeatures,
          Procedures::Service::Start,
          Procedures::Crond::Start,
          Procedures::SyncPlans::Enable,
          Procedures::MaintenanceMode::DisableMaintenanceMode,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::PostMigrations.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Procedures::RefreshFeatures,
          Procedures::Service::Start,
          Procedures::Crond::Start,
          Procedures::SyncPlans::Enable,
          Procedures::MaintenanceMode::DisableMaintenanceMode,
        )
      end
    end

    describe Scenarios::Update::PostUpdateChecks do
      let(:scenario) do
        Scenarios::Update::PostUpdateChecks.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::PostUpdateChecks.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Checks::Foreman::FactsNames,
          Checks::ForemanTasks::NotPaused,
          Checks::ServerPing,
          Checks::ServicesUp,
          Checks::SystemRegistration,
          Procedures::Packages::CheckForReboot,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::PostUpdateChecks.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Checks::Foreman::FactsNames,
          Checks::ForemanTasks::NotPaused,
          Checks::ServerPing,
          Checks::ServicesUp,
          Checks::SystemRegistration,
          Procedures::Packages::CheckForReboot,
        )
      end
    end
  end

  context 'Foreman update' do
    before(:each) do
      assume_foreman_present
      ForemanMaintain.config.stubs(:manage_crond).returns(true)
    end

    describe Scenarios::Update::PreUpdateCheck do
      let(:scenario) do
        Scenarios::Update::PreUpdateCheck.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::PreUpdateCheck.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Checks::Foreman::FactsNames,
          Checks::ForemanTasks::NotPaused,
          Checks::ServerPing,
          Checks::ServicesUp,
          Checks::SystemRegistration,
          Checks::CheckHotfixInstalled,
          Checks::CheckTmout,
          Checks::CheckUpstreamRepository,
          Checks::Disk::AvailableSpace,
          Checks::Disk::AvailableSpaceCandlepin,
          Checks::Foreman::CheckCorruptedRoles,
          Checks::Foreman::CheckDuplicatePermissions,
          Checks::Foreman::TuningRequirements,
          Checks::ForemanTasks::Invalid::CheckOld,
          Checks::ForemanTasks::Invalid::CheckPendingState,
          Checks::ForemanTasks::Invalid::CheckPlanningState,
          Checks::ForemanTasks::NotRunning,
          Checks::NonRhPackages,
          Checks::PackageManager::Dnf::ValidateDnfConfig,
          Checks::Repositories::CheckNonRhRepository,
          Checks::CheckIpv6Disable,
          Checks::Repositories::Validate,
          Checks::Pulpcore::NoRunningTasks,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::PreUpdateCheck.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Checks::Foreman::FactsNames,
          Checks::ForemanTasks::NotPaused,
          Checks::ServerPing,
          Checks::ServicesUp,
          Checks::SystemRegistration,
          Checks::CheckHotfixInstalled,
          Checks::CheckTmout,
          Checks::CheckUpstreamRepository,
          Checks::Disk::AvailableSpace,
          Checks::Disk::AvailableSpaceCandlepin,
          Checks::Foreman::CheckCorruptedRoles,
          Checks::Foreman::CheckDuplicatePermissions,
          Checks::Foreman::TuningRequirements,
          Checks::ForemanTasks::Invalid::CheckOld,
          Checks::ForemanTasks::Invalid::CheckPendingState,
          Checks::ForemanTasks::Invalid::CheckPlanningState,
          Checks::ForemanTasks::NotRunning,
          Checks::NonRhPackages,
          Checks::PackageManager::Dnf::ValidateDnfConfig,
          Checks::Repositories::CheckNonRhRepository,
          Checks::CheckIpv6Disable,
          Checks::Repositories::Validate,
          Checks::Pulpcore::NoRunningTasks,
        )
      end
    end

    describe Scenarios::Update::PreMigrations do
      let(:scenario) do
        Scenarios::Update::PreMigrations.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::PreMigrations.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Procedures::Packages::Update,
          Procedures::MaintenanceMode::EnableMaintenanceMode,
          Procedures::Crond::Stop,
          Procedures::SyncPlans::Disable,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::PreMigrations.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Procedures::Packages::Update,
          Procedures::MaintenanceMode::EnableMaintenanceMode,
          Procedures::Crond::Stop,
          Procedures::SyncPlans::Disable,
        )
      end
    end

    describe Scenarios::Update::Migrations do
      let(:scenario) do
        Scenarios::Update::Migrations.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::Migrations.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Procedures::Service::Stop,
          Procedures::Packages::Update,
          Procedures::Installer::Run,
          Procedures::Installer::UpgradeRakeTask,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::Migrations.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Procedures::Service::Stop,
          Procedures::Packages::Update,
          Procedures::Installer::Run,
          Procedures::Installer::UpgradeRakeTask,
        )
      end
    end

    describe Scenarios::Update::PostMigrations do
      let(:scenario) do
        Scenarios::Update::PostMigrations.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::PostMigrations.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Procedures::RefreshFeatures,
          Procedures::Service::Start,
          Procedures::Crond::Start,
          Procedures::SyncPlans::Enable,
          Procedures::MaintenanceMode::DisableMaintenanceMode,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::PostMigrations.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Procedures::RefreshFeatures,
          Procedures::Service::Start,
          Procedures::Crond::Start,
          Procedures::SyncPlans::Enable,
          Procedures::MaintenanceMode::DisableMaintenanceMode,
        )
      end
    end

    describe Scenarios::Update::PostUpdateChecks do
      let(:scenario) do
        Scenarios::Update::PostUpdateChecks.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::PostUpdateChecks.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Checks::Foreman::FactsNames,
          Checks::ForemanTasks::NotPaused,
          Checks::ServerPing,
          Checks::ServicesUp,
          Checks::SystemRegistration,
          Procedures::Packages::CheckForReboot,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::PostUpdateChecks.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Checks::Foreman::FactsNames,
          Checks::ForemanTasks::NotPaused,
          Checks::ServerPing,
          Checks::ServicesUp,
          Checks::SystemRegistration,
          Procedures::Packages::CheckForReboot,
        )
      end
    end
  end

  context 'Katello update' do
    before(:each) do
      assume_katello_present
      ForemanMaintain.config.stubs(:manage_crond).returns(true)
    end

    describe Scenarios::Update::PreUpdateCheck do
      let(:scenario) do
        Scenarios::Update::PreUpdateCheck.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::PreUpdateCheck.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Checks::Foreman::FactsNames,
          Checks::ForemanTasks::NotPaused,
          Checks::ServerPing,
          Checks::ServicesUp,
          Checks::SystemRegistration,
          Checks::CheckHotfixInstalled,
          Checks::CheckTmout,
          Checks::CheckUpstreamRepository,
          Checks::Disk::AvailableSpace,
          Checks::Disk::AvailableSpaceCandlepin,
          Checks::Foreman::CheckCorruptedRoles,
          Checks::Foreman::CheckDuplicatePermissions,
          Checks::Foreman::TuningRequirements,
          Checks::ForemanTasks::Invalid::CheckOld,
          Checks::ForemanTasks::Invalid::CheckPendingState,
          Checks::ForemanTasks::Invalid::CheckPlanningState,
          Checks::ForemanTasks::NotRunning,
          Checks::NonRhPackages,
          Checks::PackageManager::Dnf::ValidateDnfConfig,
          Checks::Repositories::CheckNonRhRepository,
          Checks::CheckIpv6Disable,
          Checks::Repositories::Validate,
          Checks::Pulpcore::NoRunningTasks,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::PreUpdateCheck.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Checks::Foreman::FactsNames,
          Checks::ForemanTasks::NotPaused,
          Checks::ServerPing,
          Checks::ServicesUp,
          Checks::SystemRegistration,
          Checks::CheckHotfixInstalled,
          Checks::CheckTmout,
          Checks::CheckUpstreamRepository,
          Checks::Disk::AvailableSpace,
          Checks::Disk::AvailableSpaceCandlepin,
          Checks::Foreman::CheckCorruptedRoles,
          Checks::Foreman::CheckDuplicatePermissions,
          Checks::Foreman::TuningRequirements,
          Checks::ForemanTasks::Invalid::CheckOld,
          Checks::ForemanTasks::Invalid::CheckPendingState,
          Checks::ForemanTasks::Invalid::CheckPlanningState,
          Checks::ForemanTasks::NotRunning,
          Checks::NonRhPackages,
          Checks::PackageManager::Dnf::ValidateDnfConfig,
          Checks::Repositories::CheckNonRhRepository,
          Checks::CheckIpv6Disable,
          Checks::Repositories::Validate,
          Checks::Pulpcore::NoRunningTasks,
        )
      end
    end

    describe Scenarios::Update::PreMigrations do
      let(:scenario) do
        Scenarios::Update::PreMigrations.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::PreMigrations.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Procedures::Packages::Update,
          Procedures::MaintenanceMode::EnableMaintenanceMode,
          Procedures::Crond::Stop,
          Procedures::SyncPlans::Disable,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::PreMigrations.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Procedures::Packages::Update,
          Procedures::MaintenanceMode::EnableMaintenanceMode,
          Procedures::Crond::Stop,
          Procedures::SyncPlans::Disable,
        )
      end
    end

    describe Scenarios::Update::Migrations do
      let(:scenario) do
        Scenarios::Update::Migrations.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::Migrations.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Procedures::Service::Stop,
          Procedures::Packages::Update,
          Procedures::Installer::Run,
          Procedures::Installer::UpgradeRakeTask,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::Migrations.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Procedures::Service::Stop,
          Procedures::Packages::Update,
          Procedures::Installer::Run,
          Procedures::Installer::UpgradeRakeTask,
        )
      end
    end

    describe Scenarios::Update::PostMigrations do
      let(:scenario) do
        Scenarios::Update::PostMigrations.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::PostMigrations.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Procedures::RefreshFeatures,
          Procedures::Service::Start,
          Procedures::Crond::Start,
          Procedures::SyncPlans::Enable,
          Procedures::MaintenanceMode::DisableMaintenanceMode,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::PostMigrations.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Procedures::RefreshFeatures,
          Procedures::Service::Start,
          Procedures::Crond::Start,
          Procedures::SyncPlans::Enable,
          Procedures::MaintenanceMode::DisableMaintenanceMode,
        )
      end
    end

    describe Scenarios::Update::PostUpdateChecks do
      let(:scenario) do
        Scenarios::Update::PostUpdateChecks.new
      end

      it 'composes all steps on EL8' do
        Scenarios::Update::PostUpdateChecks.any_instance.stubs(:el_major_version).returns(8)

        assert_scenario_has_steps(
          scenario,
          Checks::Foreman::FactsNames,
          Checks::ForemanTasks::NotPaused,
          Checks::ServerPing,
          Checks::ServicesUp,
          Checks::SystemRegistration,
          Procedures::Packages::CheckForReboot,
        )
      end

      it 'composes all steps on EL9' do
        Scenarios::Update::PostUpdateChecks.any_instance.stubs(:el_major_version).returns(9)

        assert_scenario_has_steps(
          scenario,
          Checks::Foreman::FactsNames,
          Checks::ForemanTasks::NotPaused,
          Checks::ServerPing,
          Checks::ServicesUp,
          Checks::SystemRegistration,
          Procedures::Packages::CheckForReboot,
        )
      end
    end
  end
end
