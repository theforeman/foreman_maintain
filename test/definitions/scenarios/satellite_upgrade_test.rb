require 'test_helper'

describe "satellite upgrade scenarios" do
  include DefinitionsTestHelper

  before(:each) do
    assume_satellite_present
    mock_satellite_maintain_config
  end

  describe Scenarios::Satellite::Abstract do
    let(:expected_scenarios) do
      [Scenarios::Satellite::Migrations, Scenarios::Satellite::PostMigrations,
       Scenarios::Satellite::PostUpgradeChecks, Scenarios::Satellite::PreMigrations,
       Scenarios::Satellite::PreUpgradeCheck]
    end

    it 'is present when running 6.15' do
      Features::Satellite.any_instance.stubs(:current_version).returns('6.15')

      scenarios = find_scenarios({ :tags => [:upgrade_scenario] })

      expected_scenarios.each do |exp|
        assert scenarios.find { |s| s.is_a? exp }, "Expected #{exp} to be present"
      end
    end

    it 'is not present when already on 6.16' do
      Features::Satellite.any_instance.stubs(:current_version).returns('6.16')

      scenarios = find_scenarios({ :tags => [:upgrade_scenario] })

      assert_empty scenarios
    end

    it 'is present when 6.16 upgrade in progress' do
      Features::Satellite.any_instance.stubs(:current_version).returns('6.16')
      ForemanMaintain.stubs(:upgrade_in_progress).returns('6.16')

      scenarios = find_scenarios({ :tags => [:upgrade_scenario] })

      expected_scenarios.each do |exp|
        assert scenarios.find { |s| s.is_a? exp }, "Expected #{exp} to be present"
      end
    end

    it 'sets target_version to 6.16' do
      Features::Satellite.any_instance.stubs(:current_version).returns('6.15')

      scenarios = find_scenarios({ :tags => [:upgrade_scenario] })

      scenarios.each do |scenario|
        assert_equal '6.16', scenario.target_version
      end
    end
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
