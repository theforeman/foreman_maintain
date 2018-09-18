require 'test_helper'

describe Checks::Foreman::PuppetClassDuplicates do
  include DefinitionsTestHelper

  subject do
    Checks::Foreman::PuppetClassDuplicates.new
  end

  before do
    assume_feature_present(:foreman_database, :present? => true)
  end

  it 'should fail when there are duplicate Puppet classes' do
    dups = [{ 'name' => 'duplicate name', 'name_count' => 6 },
            { 'name' => 'duplicate again', 'name_count' => 8 }]
    subject.stubs(:find_duplicate_names).returns(dups)
    result = run_check subject
    assert result.fail?, 'Check expected to fail'
  end

  it 'should succeed when there are duplicate Puppet classes' do
    subject.stubs(:find_duplicate_names).returns([])
    result = run_check subject
    assert result.success?, 'Check expected to succeed'
  end
end
