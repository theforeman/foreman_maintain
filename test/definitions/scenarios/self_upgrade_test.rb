require 'test_helper'

module Scenarios
  describe ForemanMaintain::Scenarios::SelfUpgradeBase do
    include DefinitionsTestHelper

    describe 'with default params' do
      let(:scenario) do
        ForemanMaintain::Scenarios::SelfUpgradeBase.new
      end

      it 'computes the target version correctly coming from normal release 6.10.0' do
        assume_satellite_present do |feature_class|
          feature_class.any_instance.stubs(:current_version => version('6.10.0'))
        end

        assert_equal '6.11', scenario.target_version
      end

      it 'computes the target version correctly coming from an async release 6.11.1.1' do
        assume_satellite_present do |feature_class|
          feature_class.any_instance.stubs(:current_version => version('6.11.1.1'))
        end

        assert_equal '6.12', scenario.target_version
      end
    end
  end
end
