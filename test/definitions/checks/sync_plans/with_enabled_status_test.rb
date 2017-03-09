require 'test_helper'

describe Checks::SyncPlans::WithEnabledStatus do
  include DefinitionsTestHelper

  subject do
    Checks::SyncPlans::WithEnabledStatus.new
  end

  it 'passes when no active sync plans' do
    assume_feature_present(:sync_plans, :active_sync_plans_count => 0)
    result = run_check(subject)
    assert result.success?
  end

  it 'fails when active sync plans are present' do
    assume_feature_present(:sync_plans, :active_sync_plans_count => 2)
    result = run_check(subject)
    assert result.fail?
    assert_match 'There are total 2 active sync plans in the system', result.output
    assert_equal [Procedures::SyncPlans::Disable], subject.next_steps.map(&:class)
  end
end
