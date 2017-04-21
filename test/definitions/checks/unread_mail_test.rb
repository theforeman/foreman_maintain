require 'test_helper'

describe Checks::UnreadMail do
  include DefinitionsTestHelper

  subject { Checks::UnreadMail.new }

  it 'passes when no mails found for root user' do
    subject.stubs(:file_exists?).returns(true)
    subject.stubs(:mails_count).returns(0)
    result = run_check(subject)
    assert result.success?
  end

  it "warning if mails found in root user's mailbox" do
    subject.stubs(:file_exists?).returns(true)
    subject.stubs(:mails_count).returns(5)
    result = run_check(subject)
    assert result.warning?
    assert_match "WARNING: Found 5 mail(s) in root's mailbox.", result.output
    assert_equal [Procedures::SystemMailbox::List, Procedures::SystemMailbox::Clear],
                 subject.next_steps.map(&:class)
  end
end
