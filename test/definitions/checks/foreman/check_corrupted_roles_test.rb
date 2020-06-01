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
    dups = [{ 'role_id' => '31', 'role_name' => 'demoRole', 'permission_name' => 'edit_hosts', \
              'resource_type' => 'Host' },
            { 'role_id' => '31', 'role_name' => 'demoRole', 'permission_name' => 'view_hosts', \
              'resource_type' => 'xyz' }]
    subject.stubs(:find_filter_permissions).returns(dups)
    result = run_check(subject)
    assert result.fail?, 'Check expected to fail'
    assert_match 'There are filters having permissions with multiple resource types. ' \
                  "Roles with such filters are:\ndemoRole", result.output
    assert_equal [Procedures::Foreman::FixCorruptedRoles],
                 subject.next_steps.map(&:class)
  end
end
