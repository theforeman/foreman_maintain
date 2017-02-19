require File.expand_path('../test_helper', File.dirname(__FILE__))

module DefinitionsTestHelper
  include ForemanMaintain::Concerns::Finders

  def detector
    @detector ||= ForemanMaintain.detector
  end

  def load_feature(feature_label)
    feature = detector.send(:autodetect_features)[feature_label.to_sym].first
    raise "Feature #{feature_label} not present in autodetect features" unless feature
    yield feature
  end

  def assume_feature_present(feature_label)
    load_feature(feature_label) do |feature|
      feature.stubs(:present? => true)
      yield feature if block_given?
    end
  end

  def assume_feature_absent(feature_label)
    load_feature(feature_label) do |feature|
      feature.stubs(:present? => false)
      yield feature if block_given?
    end
  end

  def version(version_str)
    ForemanMaintain::Concerns::SystemHelpers::Version.new(version_str)
  end

  def self.included(base)
    base.instance_eval do
      after do
        detector.refresh
      end
    end
  end

  # given the current feature assumptions (see assume_feature_present and
  # assume_feature_absent), assert the scenario with given filter is considered
  # present
  def assert_scenario(filter)
    scenario = find_scenarios(:tags => [:pre_upgrade_check, :satellite_6_2]).first
    assert scenario, "Expected the scenario #{filter} to be present"
    scenario
  end

  # given the current feature assumptions (see assume_feature_present and
  # assume_feature_absent), assert the scenario with given filter is considered
  # absent
  def refute_scenario(filter)
    scenario = find_scenarios(:tags => [:pre_upgrade_check, :satellite_6_2]).first
    refute scenario, "Expected the scenario #{filter} to be absent"
  end
end

ForemanMaintain.setup
