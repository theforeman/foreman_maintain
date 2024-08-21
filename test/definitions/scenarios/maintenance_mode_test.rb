require 'test_helper'

describe "maintenance mode scenarios" do
  include DefinitionsTestHelper

  describe ForemanMaintain::Scenarios::MaintenanceModeStart do
    let(:scenario) do
      ForemanMaintain::Scenarios::MaintenanceModeStart.new
    end

    it 'composes all steps' do
      assert_scenario_has_steps(
        scenario,
        Procedures::MaintenanceMode::EnableMaintenanceMode,
        Procedures::Crond::Stop,
        Procedures::SyncPlans::Disable,
      )
    end
  end

  describe ForemanMaintain::Scenarios::MaintenanceModeStop do
    let(:scenario) do
      ForemanMaintain::Scenarios::MaintenanceModeStop.new
    end

    it 'composes all steps' do
      assert_scenario_has_steps(
        scenario,
        Procedures::MaintenanceMode::DisableMaintenanceMode,
        Procedures::Crond::Start,
        Procedures::SyncPlans::Enable,
      )
    end
  end

  describe ForemanMaintain::Scenarios::MaintenanceModeStatus do
    let(:scenario) do
      ForemanMaintain::Scenarios::MaintenanceModeStatus.new
    end

    it 'composes all steps' do
      assert_scenario_has_steps(
        scenario,
        Checks::MaintenanceMode::CheckConsistency,
      )
    end
  end

  describe ForemanMaintain::Scenarios::IsMaintenanceMode do
    let(:scenario) do
      ForemanMaintain::Scenarios::IsMaintenanceMode.new
    end

    it 'composes all steps' do
      assert_scenario_has_steps(
        scenario,
        Procedures::MaintenanceMode::IsEnabled,
      )
    end
  end
end
