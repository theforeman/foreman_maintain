require 'test_helper'

require_relative '../test_helper'
require_relative '../../../definitions/checks/check_sha1_certificate_authority'

describe Checks::CheckSha1CertificateAuthority do
  include DefinitionsTestHelper

  subject { Checks::CheckSha1CertificateAuthority.new }

  let(:ca_cert) do
    File.join(File.dirname(__FILE__), '../../data/certs/ca-sha1.crt')
  end

  let(:output) do
    <<~MSG
      Server CA certificate #{ca_cert} signed with sha1 which will break on upgrade.
      Update the server CA certificate with one signed with sha256 or
      stronger then proceed with the upgrade.
    MSG
  end

  it 'throws an error message when server CA certificate is signed with sha1' do
    assume_feature_present(:katello)
    assume_feature_present(
      :installer,
      answers: { 'certs' => { 'server_ca_cert' => ca_cert } }
    )
    result = run_step(subject)

    assert result.fail?
    assert_equal result.output, output
  end

  it 'succeeds when using default certificates' do
    assume_feature_present(:katello)
    assume_feature_present(
      :installer,
      answers: { 'certs' => { 'server_ca_cert' => nil } }
    )
    result = run_step(subject)

    assert result.success?
  end

  it 'throws an error if the certificate is incorrectly formatted' do
    assume_feature_present(:katello)
    assume_feature_present(
      :installer,
      answers: { 'certs' => { 'server_ca_cert' => 'ca-sha1.crt' } }
    )
    File.expects(:binread).
      with('ca-sha1.crt').
      returns('15231421------BEGIN CERTIFICATE------alksddkdkd-----END CERTIFICATE-----')
    result = run_step(subject)

    assert result.fail?
  end
end
