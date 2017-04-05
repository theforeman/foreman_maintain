require File.expand_path('../test_helper', File.dirname(__FILE__))

module DefinitionsTestHelper
  include ForemanMaintain::Concerns::Finders

  def detector
    @detector ||= ForemanMaintain.detector
  end

  def feature_class(feature_label)
    feature_class = detector.send(:autodetect_features)[feature_label.to_sym].first
    raise "Feature #{feature_label} not present in autodetect features" unless feature_class
    feature_class
  end

  def assume_feature_present(feature_label, stubs = nil)
    feature_class = self.feature_class(feature_label)
    feature_class.stubs(:present? => true)
    feature_class.any_instance.stubs(stubs) if stubs
    yield feature_class if block_given?
  end

  def assume_feature_absent(feature_label)
    feature_class(feature_label) do |feature_class|
      feature_class.stubs(:present? => false)
    end
  end

  def run_step(step)
    ForemanMaintain::Runner::Execution.new(step, Support::LogReporter.new).tap(&:run)
  end

  alias run_check run_step
  alias run_procedure run_step

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
    scenario = find_scenarios(filter).first
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
