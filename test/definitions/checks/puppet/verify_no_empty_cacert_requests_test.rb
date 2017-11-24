require 'test_helper'

describe Checks::Puppet::VerifyNoEmptyCacertRequests do
  include DefinitionsTestHelper

  subject do
    Checks::Puppet::VerifyNoEmptyCacertRequests.new
  end

  let :cacert_requests_directory do
    '/var/lib/puppet/ssl/ca/requests'
  end

  it 'passes when no empty cacert file present' do
    assume_feature_present(
      :puppet_server,
      :cacert_requests_directory => cacert_requests_directory,
      :find_empty_cacert_request_files => []
    )
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails if empty cacert file(s) found' do
    assume_feature_present(
      :puppet_server,
      :cacert_requests_directory => cacert_requests_directory,
      :cacert_requests_dir_exists? => true,
      :find_empty_cacert_request_files => ["#{cacert_requests_directory}/test.pem"]
    )
    result = run_check(subject)
    assert result.fail?, 'Check expected to fail'
    assert_match "Found 1 empty file(s) under #{cacert_requests_directory}", result.output
    assert_equal [Procedures::Puppet::DeleteEmptyCaCertRequestFiles],
                 subject.next_steps.map(&:class)
  end
end
