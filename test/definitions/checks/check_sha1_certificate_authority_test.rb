require 'test_helper'

require_relative '../test_helper'
require_relative '../../../definitions/checks/check_sha1_certificate_authority'

describe Checks::CheckSha1CertificateAuthority do
  include DefinitionsTestHelper

  subject { Checks::CheckSha1CertificateAuthority.new }

  let(:ca_cert) do
    <<~CERT
      -----BEGIN CERTIFICATE-----
      MIIDHTCCAgWgAwIBAgIUK+x25LNYYMHS83aWDnAYviwxEYEwDQYJKoZIhvcNAQEL
      BQAwHjEcMBoGA1UEAwwTVGVzdCBTZWxmLVNpZ25lZCBDQTAeFw0yMDExMTgwMjMw
      NDNaFw0zMDExMTYwMjMwNDNaMB4xHDAaBgNVBAMME1Rlc3QgU2VsZi1TaWduZWQg
      Q0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC92114uygw5KcqPCz1
      E/Cwd3Lo2ytyPD9FchWKPOxXpNisHMOr4zAfsxERXmgBLawHIkqc2Xae3TqHGGQa
      ll3J3HukwghZQAyjcNG/Q2Q2QqfQW1tzxHRnz2EKBoRoyhmVXcnu+qBoEgkf5QI/
      Rk9HzLJINZPcZuMEkRgcf5q1h/F+PY2yCMwT5qjB6whn6zX6FP6G3//fRtkZw4cI
      FPPjKJedbHlYEifRigmJfu+T5Q5xz19Og/1zDwfl7is5eBUV+KEoIE7UpmvR1UrM
      +T6WYl3vxeM08y1QU6vR9GqummDMinfWLj0hV+dYwI9/1fHIjfPqgxPUa5AGw7ik
      vyrvAgMBAAGjUzBRMB0GA1UdDgQWBBQz80R5aRb/egnEMKHQonUM3xgj6DAfBgNV
      HSMEGDAWgBQz80R5aRb/egnEMKHQonUM3xgj6DAPBgNVHRMBAf8EBTADAQH/MA0G
      CSqGSIb3DQEBCwUAA4IBAQCdiBvQx6ExmteTzwkGCheKwUMvzCehuwvpoJRE/JXo
      zz67414oyWXkSN8/9HE3nkH/xxunD/Ni+N9ppk7iicSpyOKfdDXiaS8qq1O1OXCx
      CjoVuIFAPFWOEEhLdnb1v8YVWx2JwcbGvhCLNSoK1a6uwCmWixtoeQiKspBfwFcb
      wfU9qNdXsezBljahE4Q2E4SR+XclA6iHdooX4ajnleamqeH0ephyCqvMAhzfJA5F
      O1+SJRFbIjwfKxsEJS6Czrn+EU2eLtxk5g5+oO06ZYj4rVOfgc2Wc0+cisgP0fT/
      WVkAxgGS6L0jGvZSisEUBpoidJNddWnf9mzUT2kJ5DCO
      -----END CERTIFICATE-----
      -----BEGIN CERTIFICATE-----
      MIICwzCCAasCFCfqmT5iimHv5Qw7DMKZztytQza5MA0GCSqGSIb3DQEBBQUAMB4x
      HDAaBgNVBAMME1Rlc3QgU2VsZi1TaWduZWQgQ0EwHhcNMjQxMjA2MTk1NzM2WhcN
      MzQxMjA0MTk1NzM2WjAeMRwwGgYDVQQDDBNUZXN0IFNlbGYtU2lnbmVkIENBMIIB
      IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2SygWdi+BjZRyo8G5WW/527S
      JB3Mpkc35G0RQ+hszXlH6XqFw5NTcTebF5UnJ/DtuKQ0r4FAmJopH5/bejysb7xe
      tV6vgjcga3C7XVuHs1dbU7NUVWEiy0VvhI/znIK7HQ2AI//5v8CaDMxnBD4El55Y
      dagpBFCKuiuKTy4G1l4opeZGJe5ZFs10bPX5VbrqJs6l1p5C+ylrJmMxAwTtnq1Y
      qFu9B8k9wjZYTBFcEAO4CEAs/EAIfQZcd6XCq2L/YhofqBXy7Nr97NZgPUH8UtZA
      nTbG0P0dEBiSEx0rbbIg2ToAhcgLAgzPZbVV+fon/V2K7yq/Y+XQWMMGqTeuZwID
      AQABMA0GCSqGSIb3DQEBBQUAA4IBAQB7UCCFbs2kkpFR2epS97Zc7/OBd1M9ZLCh
      YRLJEjywrEnc/m8KQ9TqVSxWnk8O2Ld7hkrME4fZ+S8riXXrjv8kfRImoZE/3h2f
      QDmKOS10d79ehEtgSKBToukEcwgL5q/PjQ840wEjJK5gEG3UoFXIl3/EkvPi8Vrq
      ELBKYJhzaJA1g0ziOZWJh/sXI9ryIJ9XHUPwx5elqdtXMR0SRpvo1FmtATgBtPga
      wQ6H2KHLnas9h1owoyPETxYnd7qgbNORGSglhH0PiUTbucD6ozU+VcBuq9qPJnwZ
      76lKsVXoyGQydEuEYOmYstJqE+nBfVgPG4OwgHHHt99htimjCcn3
      -----END CERTIFICATE-----
    CERT
  end

  it 'throws an error message when server CA certificate is signed with sha1' do
    assume_feature_present(:katello)
    assume_feature_present(
      :installer,
      answers: { 'certs' => { 'server_ca_cert' => 'ca-sha1.crt' } }
    )
    File.expects(:binread).with('ca-sha1.crt').returns(ca_cert)
    result = run_step(subject)

    assert result.fail?
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
    File.expects(:binread).with('ca-sha1.crt').returns('15231421')
    result = run_step(subject)

    assert result.fail?
  end
end