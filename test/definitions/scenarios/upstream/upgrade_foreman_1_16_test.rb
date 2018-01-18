require 'test_helper'

module Scenarios
  describe Foreman_1_16::PreUpgradeCheck do
    include DefinitionsTestHelper

    before do
      assume_feature_present(:upstream) do |feature|
        feature.any_instance.stubs(:current_version => version('1.15'))
      end
      assume_feature_present(:foreman_tasks)
    end

    let :scenario do
      assert_scenario(:tags => [:pre_upgrade_checks, :upgrade_to_foreman_1_16])
    end

    it 'is valid for 1.15 and 1.15.z version' do
      assert_scenario(:tags => [:pre_upgrade_checks, :upgrade_to_foreman_1_16])

      assume_feature_present(:upstream) do |feature_class|
        feature_class.any_instance.stubs(:current_version => version('1.15'))
      end
      detector.refresh
      assert_scenario(:tags => [:pre_upgrade_checks, :upgrade_to_foreman_1_16])

      assume_feature_present(:upstream) do |feature_class|
        feature_class.any_instance.stubs(:current_version => version('1.15.1'))
      end
      detector.refresh
      assert_scenario(:tags => [:pre_upgrade_checks, :upgrade_to_foreman_1_16])
    end

    it 'is valid only for 15.1.z versions' do
      assert_scenario(:tags => [:pre_upgrade_checks, :upgrade_to_foreman_1_16])

      assume_feature_present(:upstream) do |feature_class|
        feature_class.any_instance.stubs(:current_version => version('1.14.1'))
      end
      detector.refresh
      refute_scenario(:tags => [:pre_upgrade_checks, :upgrade_to_foreman_1_16])

      assume_feature_present(:upstream) do |feature_class|
        feature_class.any_instance.stubs(:current_version => version('1.16.1'))
      end
      detector.refresh
      refute_scenario(:tags => [:pre_upgrade_checks, :upgrade_to_foreman_1_16])

      assume_feature_absent(:upstream)
      detector.refresh
      refute_scenario(:tags => [:pre_upgrade_checks, :upgrade_to_foreman_1_16])
    end

    it 'composes the pre upgrade checks for migration from foreman 1.15.z to 1.16' do
      assert(scenario.steps.find { |step| step.is_a? Checks::ForemanTasks::NotPaused })
      assert(scenario.steps.find { |step| step.is_a? Checks::ForemanTasks::NotRunning })
    end
  end
end
