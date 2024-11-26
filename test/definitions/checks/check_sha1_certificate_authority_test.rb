require 'test_helper'

require_relative '../test_helper'
require_relative '../../../definitions/checks/check_sha1_certificate_authority'

describe Checks::CheckSha1CertificateAuthority do
  include DefinitionsTestHelper

  subject { Checks::CheckSha1CertificateAuthority.new }

  let(:ca_cert) do
    <<~CERT
      -----BEGIN CERTIFICATE-----
      MIIDHTCCAgWgAwIBAgIUbkOgb3ORoG8G9K3aCqGHvmxjMXQwDQYJKoZIhvcNAQEF
      BQAwHjEcMBoGA1UEAwwTVGVzdCBTZWxmLVNpZ25lZCBDQTAeFw0yNDExMjYyMDMw
      MTRaFw0zNDExMjQyMDMwMTRaMB4xHDAaBgNVBAMME1Rlc3QgU2VsZi1TaWduZWQg
      Q0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDca251YgujAdBW9Dk7
      cHcAPpGkDdQitpL63dQxMqAW3qPVErnjouHe3HDhE2ibVoccBGS5vLjTedXMJVII
      rGvJyqiY2OR3iANb3KA5LswKjty/FPVC+XxKeX4ZPHBXNrvRkZ0K4Ih3cr8V4ZKF
      iz9/398HHB+ZfhWLSsVe89SSoZuk86DNnc5MzaU/0fS4OCIlNcs67s8geGQMbIJh
      F9gqoCziiWu4eQU+6q3nxLzXJUGePGv6HlfI51W9kXu2pK79TMxK8nqan0yBhVqO
      Ll9M8j6BN2V7/syMZlBhQDEUeZy23nzdXQVSwVGLaeqO5pJK6Z8Li1oBS0PPUS1k
      Ck4HAgMBAAGjUzBRMB0GA1UdDgQWBBSClr59wc0O6GmE7jnxBwVC2hPurTAfBgNV
      HSMEGDAWgBSClr59wc0O6GmE7jnxBwVC2hPurTAPBgNVHRMBAf8EBTADAQH/MA0G
      CSqGSIb3DQEBBQUAA4IBAQDa59NGJa8Bx7rmWGNqXITg+ZLg4pue/7XYYVuOlE12
      IN+WrtU0hZxGX0LTf3fVsSZHByXaTQ+9Td8X+aEtX8OJLXdckk6kpCePnregd2cM
      BrFoUscVNdyThJnPrPYTMufyS38VByS5kWZW5WetlOYxyl56sCIjEJp+TYPI+Yvk
      HwvgixsbXZuKa19/m6gMF1hn58hMHt+CG/24lQgWXzvAxMC23xcNLRoiBh3YCejh
      JA7VJrbYCR4PypDoYm3A7IAmj1nNCcrfahf1G8QNkxdntepQ2kf32PAKAQszXEMB
      Lh3FzbuCRGvqrCLF7CrcoGzvSEge3Pv/lUSZ3uoOobp/
      -----END CERTIFICATE-----
    CERT
  end

  it 'throws an error message when server CA certificate is signed with sha1' do
    assume_feature_present(:katello)
    assume_feature_present(
      :installer,
      answers: { 'certs' => { 'server_ca_cert' => 'ca-sha1.crt' } }
    )
    File.expects(:read).with('ca-sha1.crt').returns(ca_cert)
    result = run_step(subject)

    assert result.fail?
  end
end
