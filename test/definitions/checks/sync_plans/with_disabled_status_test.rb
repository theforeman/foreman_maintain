require 'test_helper'

describe Checks::SyncPlans::WithDisabledStatus do
  include DefinitionsTestHelper

  subject do
    Checks::SyncPlans::WithDisabledStatus.new
  end

  it 'passes when no sync plans which were disabled during pre-upgrade check' do
    assume_feature_present(:sync_plans, :disabled_plans_count => 0)
    result = run_check(subject)
    assert result.success?
  end

  it 'fails when disabled sync plans are present' do
    assume_feature_present(:sync_plans, :disabled_plans_count => 2)
    result = run_check(subject)
    assert result.fail?
    assert_match 'There are 2 disabled sync plans which needs to be enabled', result.output
    assert_equal [Procedures::SyncPlans::Enable], subject.next_steps.map(&:class)
  end
end
