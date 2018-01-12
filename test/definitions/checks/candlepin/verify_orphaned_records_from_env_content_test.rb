require 'test_helper'

describe Checks::Candlepin::VerifyOrphanedRecordsFromEnvContent do
  include DefinitionsTestHelper

  subject do
    Checks::Candlepin::VerifyOrphanedRecordsFromEnvContent.new
  end

  it 'passes when no orphaned records with null content are present in cp_env_content' do
    assume_feature_present(:candlepin, :content_ids_with_null_content_from_cp_env_content => [])
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails when orphaned records with null content are present' do
    assume_feature_present(:candlepin,
                           :content_ids_with_null_content_from_cp_env_content => [1])
    result = run_check(subject)
    assert result.fail?, 'Check expected to fail'
    assert_match '1 orphaned record(s) with null content found', result.output
    assert_equal [Procedures::Candlepin::DeleteOrphanedRecordsFromEnvContent],
                 subject.next_steps.map(&:class)
  end
end
