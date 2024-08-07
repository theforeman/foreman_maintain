require 'test_helper'

describe Procedures::ForemanTasks::Resume do
  include DefinitionsTestHelper

  subject do
    Procedures::ForemanTasks::UiInvestigate.new('search_query' => 'state = paused')
  end

  before do
    assume_feature_present(:foreman_tasks)
  end

  it 'prints information about where to look in UI for resolving the problem' do
    subject.stubs(:hostname => 'example.com')
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
    assert_equal <<~MSG.strip, result.reporter.output.strip
      Go to https://example.com/foreman_tasks/tasks?search=state+%3D+paused
      press ENTER after the tasks are resolved.
    MSG
  end
end
