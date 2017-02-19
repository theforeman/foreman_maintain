require 'test_helper'

module Scenarios
  describe PreUpgradeCheckSatellite_6_2 do
    include DefinitionsTestHelper

    before do
      assume_feature_present(:downstream) do |feature|
        feature.stubs(:current_version => version('6.1.8'))
      end
      assume_feature_present(:foreman_tasks)
    end

    let :scenario do
      assert_scenario(:tags => [:pre_upgrade_check, :satellite_6_2])
    end

    it 'is valid only for 6.1.x versions' do
      assert_scenario(:tags => [:pre_upgrade_check, :satellite_6_2])

      assume_feature_present(:downstream) do |feature|
        feature.stubs(:current_version => version('6.0.8'))
      end
      detector.refresh
      refute_scenario(:tags => [:pre_upgrade_check, :satellite_6_2])

      assume_feature_present(:downstream) do |feature|
        feature.stubs(:current_version => version('6.2.1'))
      end
      detector.refresh
      refute_scenario(:tags => [:pre_upgrade_check, :satellite_6_2])

      assume_feature_absent(:downstream)
      detector.refresh
      refute_scenario(:tags => [:pre_upgrade_check, :satellite_6_2])
    end

    it 'composes the pre upgrade checks for migration from satellite 6.1.x to 6.2' do
      assert_includes scenario.steps, check(:foreman_tasks_not_paused)
      assert_includes scenario.steps, check(:foreman_tasks_not_running)
    end
  end
end
