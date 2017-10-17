require 'test_helper'

describe Checks::ForemanTasks::NotRunning do
  include DefinitionsTestHelper

  subject do
    Checks::ForemanTasks::NotRunning.new
  end

  it 'passes when not active tasks are present' do
    assume_feature_present(:foreman_tasks, :running_tasks_count => 0)
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails when running/paused tasks are present' do
    assume_feature_present(:foreman_tasks, :running_tasks_count => 5)
    result = run_check(subject)
    assert result.fail?, 'Check expected to fail'
    msg = 'There are 5 active task(s) in the system.'
    msg += "\nPlease wait for these to complete or cancel them from the Monitor tab."
    assert_match msg, result.output
    assert_equal [Procedures::ForemanTasks::FetchTasksStatus,
                  Procedures::ForemanTasks::UiInvestigate],
                 subject.next_steps.map(&:class)
  end
end
