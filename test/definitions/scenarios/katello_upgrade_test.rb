require 'test_helper'

describe "katello upgrade scenarios" do
  include DefinitionsTestHelper

  before(:each) do
    assume_katello_present
  end

  describe Scenarios::Foreman::PreUpgradeCheck do
    let(:scenario) do
      Scenarios::Foreman::PreUpgradeCheck.new
    end

    it 'composes all steps for Foreman on EL8' do
      Scenarios::Foreman::PreUpgradeCheck.any_instance.stubs(:el_major_version).returns(8)

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
        Checks::Pulpcore::NoRunningTasks,
        Checks::NonRhPackages,
        Checks::PackageManager::Dnf::ValidateDnfConfig,
        Checks::Repositories::CheckNonRhRepository,
        Checks::Disk::AvailableSpacePostgresql13,
        Checks::CheckOrganizationContentAccessMode,
        Checks::Repositories::Validate,
      )
    end

    it 'composes all steps for Foreman on EL9' do
      Scenarios::Foreman::PreUpgradeCheck.any_instance.stubs(:el_major_version).returns(9)

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
        Checks::Pulpcore::NoRunningTasks,
        Checks::NonRhPackages,
        Checks::PackageManager::Dnf::ValidateDnfConfig,
        Checks::Repositories::CheckNonRhRepository,
        Checks::Disk::AvailableSpacePostgresql13,
        Checks::CheckOrganizationContentAccessMode,
        Checks::Repositories::Validate,
      )
    end
  end

  describe Scenarios::Foreman::PreMigrations do
    let(:scenario) do
      Scenarios::Foreman::PreMigrations.new
    end

    it 'composes all steps for Foreman on EL8' do
      Scenarios::Foreman::PreMigrations.any_instance.stubs(:el_major_version).returns(8)

      assert_scenario_has_steps(
        scenario,
        Procedures::MaintenanceMode::EnableMaintenanceMode,
        Procedures::Crond::Stop,
        Procedures::SyncPlans::Disable,
      )
    end

    it 'composes all steps for Foreman on EL9' do
      Scenarios::Foreman::PreMigrations.any_instance.stubs(:el_major_version).returns(9)

      assert_scenario_has_steps(
        scenario,
        Procedures::MaintenanceMode::EnableMaintenanceMode,
        Procedures::Crond::Stop,
        Procedures::SyncPlans::Disable,
      )
    end
  end

  describe Scenarios::Foreman::Migrations do
    let(:scenario) do
      Scenarios::Foreman::Migrations.new
    end

    it 'composes all steps for Foreman on EL8' do
      Scenarios::Foreman::Migrations.any_instance.stubs(:el_major_version).returns(8)

      assert_scenario_has_steps(
        scenario,
        Procedures::Repositories::Setup,
        Procedures::Packages::SwitchModules,
        Procedures::Packages::Update,
        Procedures::Service::Stop,
        Procedures::Packages::Update,
        Procedures::Installer::Run,
      )
    end

    it 'composes all steps for Foreman on EL9' do
      Scenarios::Foreman::Migrations.any_instance.stubs(:el_major_version).returns(9)

      assert_scenario_has_steps(
        scenario,
        Procedures::Repositories::Setup,
        Procedures::Packages::Update,
        Procedures::Service::Stop,
        Procedures::Packages::Update,
        Procedures::Installer::Run,
      )
    end
  end

  describe Scenarios::Foreman::PostMigrations do
    let(:scenario) do
      Scenarios::Foreman::PostMigrations.new
    end

    it 'composes all steps for Foreman on EL8' do
      Scenarios::Foreman::PostMigrations.any_instance.stubs(:el_major_version).returns(8)

      assert_scenario_has_steps(
        scenario,
        Procedures::RefreshFeatures,
        Procedures::Service::Start,
        Procedures::Crond::Start,
        Procedures::SyncPlans::Enable,
        Procedures::MaintenanceMode::DisableMaintenanceMode,
      )
    end

    it 'composes all steps for Foreman on EL9' do
      Scenarios::Foreman::PostMigrations.any_instance.stubs(:el_major_version).returns(9)

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

  describe Scenarios::Foreman::PostUpgradeChecks do
    let(:scenario) do
      Scenarios::Foreman::PostUpgradeChecks.new
    end

    it 'composes all steps for Foreman on EL8' do
      Scenarios::Foreman::PostUpgradeChecks.any_instance.stubs(:el_major_version).returns(8)

      assert_scenario_has_steps(
        scenario,
        Checks::Foreman::FactsNames,
        Checks::ForemanTasks::NotPaused,
        Checks::ServerPing,
        Checks::ServicesUp,
        Checks::SystemRegistration,
        Procedures::Packages::CheckForReboot,
        Procedures::Pulpcore::ContainerHandleImageMetadata,
        Procedures::Repositories::IndexKatelloRepositoriesContainerMetatdata,
      )
    end

    it 'composes all steps for Foreman on EL9' do
      Scenarios::Foreman::PostUpgradeChecks.any_instance.stubs(:el_major_version).returns(9)

      assert_scenario_has_steps(
        scenario,
        Checks::Foreman::FactsNames,
        Checks::ForemanTasks::NotPaused,
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
