require 'test_helper'

describe Checks::Foreman::CheckDuplicateRoles do
  include DefinitionsTestHelper

  subject do
    Checks::Foreman::CheckDuplicateRoles.new
  end

  it 'passes when no duplicate roles detected' do
    assume_feature_present(:foreman_database, :query => [])
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails when any duplicate entries detected for any role(s)' do
    assume_feature_present(
      :foreman_database,
      :query => [{ 'id' => 6, 'name' => 'foo' }, { 'id' => 7, 'name' => 'foo' }]
    )
    result = run_check(subject)
    assert result.fail?, 'Check expected to fail'
    assert_match 'Duplicate entries found for role(s) - foo in your DB', result.output
    assert_equal [Procedures::Foreman::RemoveDuplicateObsoleteRoles,
                  Procedures::KnowledgeBaseArticle], subject.next_steps.map(&:class)
  end
end
