require 'test_helper'

describe "capsule upgrade scenarios" do
  include DefinitionsTestHelper

  before(:each) do
    assume_feature_present(:capsule)
    mock_satellite_maintain_config
  end

  describe Scenarios::Satellite::PreUpgradeCheck do
    let(:scenario) do
      Scenarios::Satellite::PreUpgradeCheck.new
    end

    it 'composes all steps for Satellite on EL9' do
      Scenarios::Satellite::PreUpgradeCheck.any_instance.stubs(:el_major_version).returns(9)

      assert_scenario_has_steps(
        scenario,
        Checks::ServerPing,
        Checks::ServicesUp,
        Checks::SystemRegistration,
        Checks::CheckHotfixInstalled,
        Checks::CheckTmout,
        Checks::CheckSubscriptionManagerRelease,
        Checks::CheckUpstreamRepository,
        Checks::Disk::AvailableSpace,
        Checks::NonRhPackages,
        Checks::PackageManager::Dnf::ValidateDnfConfig,
        Checks::Repositories::CheckNonRhRepository,
        Checks::CheckIpv6Disable,
        Checks::Disk::PostgresqlMountpoint,
        Checks::Repositories::Validate,
        Checks::Pulpcore::NoRunningTasks,
      )
    end
  end

  describe Scenarios::Satellite::PreMigrations do
    let(:scenario) do
      Scenarios::Satellite::PreMigrations.new
    end

    it 'composes all steps for Satellite on EL9' do
      Scenarios::Satellite::PreMigrations.any_instance.stubs(:el_major_version).returns(9)

      assert_scenario_has_steps(
        scenario,
        Procedures::MaintenanceMode::EnableMaintenanceMode,
        Procedures::Crond::Stop,
        Procedures::Timer::Stop,
      )
    end
  end

  describe Scenarios::Satellite::Migrations do
    let(:scenario) do
      Scenarios::Satellite::Migrations.new
    end

    it 'composes all steps for Capsule on EL9' do
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
      )
    end
  end

  describe Scenarios::Satellite::PostMigrations do
    let(:scenario) do
      Scenarios::Satellite::PostMigrations.new
    end

    it 'composes all steps for Satellite on EL9' do
      Scenarios::Satellite::PostMigrations.any_instance.stubs(:el_major_version).returns(9)

      assert_scenario_has_steps(
        scenario,
        Procedures::RefreshFeatures,
        Procedures::Service::Start,
        Procedures::Crond::Start,
        Procedures::Timer::Start,
        Procedures::MaintenanceMode::DisableMaintenanceMode,
      )
    end
  end

  describe Scenarios::Satellite::PostUpgradeChecks do
    let(:scenario) do
      Scenarios::Satellite::PostUpgradeChecks.new
    end

    it 'composes all steps for Satellite on EL9' do
      Scenarios::Satellite::PostUpgradeChecks.any_instance.stubs(:el_major_version).returns(9)

      assert_scenario_has_steps(
        scenario,
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
