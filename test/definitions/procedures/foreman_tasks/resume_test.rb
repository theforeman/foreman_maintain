require 'test_helper'

describe Procedures::ForemanTasks::Resume do
  include DefinitionsTestHelper

  subject do
    Procedures::ForemanTasks::Resume.new
  end

  it 'passes calls hammer to resume the tasks' do
    subject.expects(:hammer).with('task resume').returns('5 tasks resumed')
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
    assert_equal result.output, '5 tasks resumed'
  end
end
