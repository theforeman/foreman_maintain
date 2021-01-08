require 'test_helper'

describe Checks::ForemanTasks::NotPaused do
  include DefinitionsTestHelper

  subject do
    Checks::ForemanTasks::NotPaused.new
  end

  it 'passes when not paused tasks are present' do
    assume_feature_present(:foreman_tasks, :paused_tasks_count => 0)
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails when paused tasks are present' do
    assume_feature_present(:foreman_tasks, :paused_tasks_count => 5)
    result = run_check(subject)
    assert result.fail?, 'Check expected to fail'
    assert_match 'There are currently 5 paused tasks in the system', result.output
    assert_equal [Procedures::ForemanTasks::Resume, Procedures::ForemanTasks::Delete,
                  Procedures::ForemanTasks::UiInvestigate],
                 subject.next_steps.map(&:class)
  end
end
