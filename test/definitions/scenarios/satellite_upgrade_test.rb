require 'test_helper'

describe "satellite upgrade scenarios" do
  include DefinitionsTestHelper

  before(:each) do
    assume_satellite_present
  end

  describe Scenarios::Satellite::PreUpgradeCheck do
    let(:scenario) do
      Scenarios::Satellite::PreUpgradeCheck.new
    end

    it 'composes all steps for Satellite on EL8' do
      Scenarios::Satellite::PreUpgradeCheck.any_instance.stubs(:el_major_version).returns(8)

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
        Checks::CheckIpv6Disable,
        Checks::Disk::AvailableSpacePostgresql13,
        Checks::CheckOrganizationContentAccessMode,
        Checks::CheckSha1CertificateAuthority,
        Checks::Repositories::Validate,
      )
    end

    it 'composes all steps for Satellite on EL9' do
      Scenarios::Satellite::PreUpgradeCheck.any_instance.stubs(:el_major_version).returns(9)

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
        Checks::CheckIpv6Disable,
        Checks::Disk::AvailableSpacePostgresql13,
        Checks::CheckOrganizationContentAccessMode,
        Checks::CheckSha1CertificateAuthority,
        Checks::Repositories::Validate,
      )
    end
  end

  describe Scenarios::Satellite::PreMigrations do
    let(:scenario) do
      Scenarios::Satellite::PreMigrations.new
    end

    it 'composes all steps for Satellite on EL8' do
      Scenarios::Satellite::PreMigrations.any_instance.stubs(:el_major_version).returns(8)

      assert_scenario_has_steps(
        scenario,
        Procedures::MaintenanceMode::EnableMaintenanceMode,
        Procedures::Crond::Stop,
        Procedures::SyncPlans::Disable,
      )
    end

    it 'composes all steps for Satellite on EL9' do
      Scenarios::Satellite::PreMigrations.any_instance.stubs(:el_major_version).returns(9)

      assert_scenario_has_steps(
        scenario,
        Procedures::MaintenanceMode::EnableMaintenanceMode,
        Procedures::Crond::Stop,
        Procedures::SyncPlans::Disable,
      )
    end
  end

  describe Scenarios::Satellite::Migrations do
    let(:scenario) do
      Scenarios::Satellite::Migrations.new
    end

    it 'composes all steps for Satellite on EL8' do
      Scenarios::Satellite::Migrations.any_instance.stubs(:el_major_version).returns(8)
      assert_scenario_has_step(scenario, Procedures::Packages::EnableModules) do |step|
        assert_equal(['satellite:el8'], step.options['module_names'])
      end

      assert_scenario_has_steps(
        scenario,
        Procedures::Repositories::Setup,
        Procedures::Packages::SwitchModules,
        Procedures::Packages::EnableModules,
        Procedures::Packages::Update,
        Procedures::Service::Stop,
        Procedures::Packages::Update,
        Procedures::Installer::Run,
        Procedures::Installer::UpgradeRakeTask,
      )
    end

    it 'composes all steps for Satellite on EL9' do
      Scenarios::Satellite::Migrations.any_instance.stubs(:el_major_version).returns(9)
      refute_scenario_has_step(scenario, Procedures::Packages::EnableModules)
      refute_scenario_has_step(scenario, Procedures::Packages::SwitchModules)

      assert_scenario_has_steps(
        scenario,
        Procedures::Repositories::Setup,
        Procedures::Packages::Update,
        Procedures::Service::Stop,
        Procedures::Packages::Update,
        Procedures::Installer::Run,
        Procedures::Installer::UpgradeRakeTask,
      )
    end
  end

  describe Scenarios::Satellite::PostMigrations do
    let(:scenario) do
      Scenarios::Satellite::PostMigrations.new
    end

    it 'composes all steps for Satellite on EL8' do
      Scenarios::Satellite::PostMigrations.any_instance.stubs(:el_major_version).returns(8)

      assert_scenario_has_steps(
        scenario,
        Procedures::RefreshFeatures,
        Procedures::Service::Start,
        Procedures::Crond::Start,
        Procedures::SyncPlans::Enable,
        Procedures::MaintenanceMode::DisableMaintenanceMode,
      )
    end

    it 'composes all steps for Satellite on EL9' do
      Scenarios::Satellite::PostMigrations.any_instance.stubs(:el_major_version).returns(9)

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

  describe Scenarios::Satellite::PostUpgradeChecks do
    let(:scenario) do
      Scenarios::Satellite::PostUpgradeChecks.new
    end

    it 'composes all steps for Satellite on EL8' do
      Scenarios::Satellite::PostUpgradeChecks.any_instance.stubs(:el_major_version).returns(8)

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

    it 'composes all steps for Satellite on EL9' do
      Scenarios::Satellite::PostUpgradeChecks.any_instance.stubs(:el_major_version).returns(9)

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
