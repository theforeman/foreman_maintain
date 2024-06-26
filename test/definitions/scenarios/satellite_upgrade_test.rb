require 'test_helper'

module Scenarios
  describe Scenarios::Satellite::Migrations do
    include DefinitionsTestHelper

    let(:scenario) do
      Scenarios::Satellite::Migrations.new
    end

    it 'composes all steps for Satellite on EL8' do
      assume_feature_present(:satellite)
      Scenarios::Satellite::Migrations.any_instance.stubs(:el_major_version).returns(8)
      assert_scenario_has_step(scenario, Procedures::Packages::EnableModules) do |step|
        assert_equal(['satellite:el8'], step.options['module_names'])
      end
    end

    it 'composes all steps for Satellite on EL9' do
      assume_feature_present(:satellite)
      Scenarios::Satellite::Migrations.any_instance.stubs(:el_major_version).returns(9)
      refute_scenario_has_step(scenario, Procedures::Packages::EnableModules)
    end

    it 'composes all steps for Capsule on EL8' do
      assume_feature_present(:capsule)
      Scenarios::Satellite::Migrations.any_instance.stubs(:el_major_version).returns(8)
      assert_scenario_has_step(scenario, Procedures::Packages::EnableModules) do |step|
        assert_equal(['satellite-capsule:el8'], step.options['module_names'])
      end
    end

    it 'composes all steps for Capsule on EL9' do
      assume_feature_present(:capsule)
      Scenarios::Satellite::Migrations.any_instance.stubs(:el_major_version).returns(9)
      refute_scenario_has_step(scenario, Procedures::Packages::EnableModules)
    end
  end
end
