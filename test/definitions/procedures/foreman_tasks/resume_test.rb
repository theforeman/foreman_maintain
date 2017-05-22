require 'test_helper'

describe Procedures::ForemanTasks::Resume do
  include DefinitionsTestHelper

  subject do
    Procedures::ForemanTasks::Resume.new
  end

  it 'passes calls hammer to resume the tasks' do
    assume_feature_present(:foreman_tasks, :resume_task_using_hammer => '5 tasks resumed')
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
    assert_equal result.output, '5 tasks resumed'
  end
end
