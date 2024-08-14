require 'test_helper'

describe "foreman upgrade scenarios" do
  include DefinitionsTestHelper

  before(:each) do
    assume_foreman_present
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
        Checks::ServerPing,
        Checks::ServicesUp,
        Checks::CheckTmout,
        Checks::Disk::AvailableSpace,
        Checks::Foreman::CheckCorruptedRoles,
        Checks::Foreman::CheckDuplicatePermissions,
        Checks::PackageManager::Dnf::ValidateDnfConfig,
        Checks::Disk::AvailableSpacePostgresql13,
        Checks::Repositories::Validate,
        Checks::Pulpcore::NoRunningTasks,
      )
    end

    it 'composes all steps for Foreman on EL9' do
      Scenarios::Foreman::PreUpgradeCheck.any_instance.stubs(:el_major_version).returns(9)

      assert_scenario_has_steps(
        scenario,
        Checks::Foreman::FactsNames,
        Checks::ServerPing,
        Checks::ServicesUp,
        Checks::CheckTmout,
        Checks::Disk::AvailableSpace,
        Checks::Foreman::CheckCorruptedRoles,
        Checks::Foreman::CheckDuplicatePermissions,
        Checks::PackageManager::Dnf::ValidateDnfConfig,
        Checks::Disk::AvailableSpacePostgresql13,
        Checks::Repositories::Validate,
        Checks::Pulpcore::NoRunningTasks,
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
      )
    end

    it 'composes all steps for Foreman on EL9' do
      Scenarios::Foreman::PreMigrations.any_instance.stubs(:el_major_version).returns(9)

      assert_scenario_has_steps(
        scenario,
        Procedures::MaintenanceMode::EnableMaintenanceMode,
        Procedures::Crond::Stop,
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
        Procedures::MaintenanceMode::DisableMaintenanceMode,
        Procedures::Crond::Start,
      )
    end

    it 'composes all steps for Foreman on EL9' do
      Scenarios::Foreman::PostMigrations.any_instance.stubs(:el_major_version).returns(9)

      assert_scenario_has_steps(
        scenario,
        Procedures::RefreshFeatures,
        Procedures::Service::Start,
        Procedures::MaintenanceMode::DisableMaintenanceMode,
        Procedures::Crond::Start,
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
        Checks::ServerPing,
        Checks::ServicesUp,
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
        Checks::ServerPing,
        Checks::ServicesUp,
        Procedures::Packages::CheckForReboot,
        Procedures::Pulpcore::ContainerHandleImageMetadata,
        Procedures::Repositories::IndexKatelloRepositoriesContainerMetatdata,
      )
    end
  end
end
