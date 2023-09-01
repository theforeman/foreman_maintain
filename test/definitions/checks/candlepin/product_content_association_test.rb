require 'test_helper'

describe Checks::Candlepin::ProductContentAssociation do
  include DefinitionsTestHelper

  subject do
    Checks::Candlepin::ProductContentAssociation.new
  end

  it 'passes when nothing found' do
    assume_feature_present(:candlepin_database) do |db|
      db.any_instance.expects(:query).returns([])
    end
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails when missing associations' do
    assume_feature_present(:candlepin_database) do |db|
      db.any_instance.expects(:query).returns([{
        'content_id' => '123',
        'uuid' => 'feed',
        'name' => 'foo',
      }])
    end
    result = run_check(subject)
    assert result.fail?, 'Check expected to fail'
    msg = "Candlepin DB is missing some Product to Content associations!\n"
    msg += 'Found 1 content entries with missing product association.'
    assert_match msg, result.output
    assert_equal [Procedures::Candlepin::ProductContentAssociation], subject.next_steps.map(&:class)
  end
end
