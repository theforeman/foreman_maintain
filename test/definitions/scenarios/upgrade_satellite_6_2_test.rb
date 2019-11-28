require 'test_helper'

module Scenarios
  describe Satellite_6_2::PreUpgradeCheck do
    include DefinitionsTestHelper

    before do
      assume_satellite_present do |feature|
        feature.any_instance.stubs(:current_version => version('6.1.8'))
      end
      assume_feature_present(:foreman_tasks)

      stub_foreman_proxy_config
    end

    let :scenario do
      assert_scenario({ :tags => :pre_upgrade_checks }, '6.2')
    end

    it 'is valid for 6.1.0 and 6.1.z version' do
      assert_scenario({ :tags => :pre_upgrade_checks }, '6.2')

      assume_satellite_present do |feature_class|
        feature_class.any_instance.stubs(:current_version => version('6.1.0'))
      end
      detector.refresh
      assert_scenario({ :tags => :pre_upgrade_checks }, '6.2')

      assume_satellite_present do |feature_class|
        feature_class.any_instance.stubs(:current_version => version('6.1.1'))
      end
      detector.refresh
      assert_scenario({ :tags => :pre_upgrade_checks }, '6.2')
    end

    it 'is valid only for 6.1.z versions' do
      assert_scenario({ :tags => :pre_upgrade_checks }, '6.2')

      assume_satellite_present do |feature_class|
        feature_class.any_instance.stubs(:current_version => version('6.0.8'))
      end
      detector.refresh
      refute_scenario({ :tags => :pre_upgrade_checks }, '6.2')

      assume_satellite_present do |feature_class|
        feature_class.any_instance.stubs(:current_version => version('6.2.1'))
      end
      detector.refresh
      refute_scenario({ :tags => :pre_upgrade_checks }, '6.2')

      assume_feature_absent(:satellite)
      detector.refresh
      refute_scenario({ :tags => :pre_upgrade_checks }, '6.2')
    end

    it 'composes the pre upgrade checks for migration from satellite 6.1.z to 6.2' do
      assert(scenario.steps.find { |step| step.is_a? Checks::ForemanTasks::NotPaused })
      assert(scenario.steps.find { |step| step.is_a? Checks::ForemanTasks::NotRunning })
    end
  end
end
