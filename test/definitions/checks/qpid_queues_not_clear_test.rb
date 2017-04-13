require 'test_helper'

describe Checks::QpidQueuesNotClear do
  include DefinitionsTestHelper

  subject do
    Checks::QpidQueuesNotClear.new
  end

  it 'runs on empty qpid queue' do
    assume_feature_present(:qpid, :count => 0)
    result = run_check(subject)
    assert result.success?
  end

  it 'fails when qpid queues are present' do
    assume_feature_present(:qpid, :count => 2)
    result = run_check(subject)
    assert result.fail?
    assert_match 'There are 2 persistent qpid queue(s) present in the system', result.output
    assert_equal [Procedures::QpidQueuesClear], subject.next_steps.map(&:class)
  end
end
