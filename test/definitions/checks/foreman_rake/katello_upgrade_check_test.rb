require 'test_helper'

describe Checks::ForemanRake::KatelloUpgradeCheck do
  include DefinitionsTestHelper

  subject do
    Checks::ForemanRake::KatelloUpgradeCheck.new
  end

  it 'passes when no active tasks are present' do
    subject.stubs(:ready_to_upgrade?).returns(true)
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails when any active tasks are present' do
    subject.stubs(:ready_to_upgrade?).returns(false)
    result = run_check(subject)
    assert result.fail?, 'Check expected to fail'
    assert_equal [Procedures::ForemanTasks::Resume, Procedures::ForemanTasks::UiInvestigate],
                 subject.next_steps.map(&:class)
  end
end
