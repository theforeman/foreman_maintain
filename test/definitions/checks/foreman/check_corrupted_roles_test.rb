require 'test_helper'

describe Checks::Foreman::CheckCorruptedRoles do
  include DefinitionsTestHelper

  subject do
    Checks::Foreman::CheckCorruptedRoles.new
  end

  it 'passes when no corupted roles detected' do
    assume_feature_present(:foreman_database, :query => [])
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails when some roles with corrupted filters detected' do
    assume_feature_present(:foreman_database, :query => [{ 'role_id' => 5 }])
    result = run_check(subject)
    assert result.fail?, 'Check expected to fail'
    assert_match 'There are user roles with inconsistent filters', result.output
    assert_equal [Procedures::Foreman::FixCorruptedRoles],
                 subject.next_steps.map(&:class)
  end
end
