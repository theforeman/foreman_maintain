class Checks::CheckSha1CertificateAuthority < ForemanMaintain::Check
  metadata do
    label :check_sha1_certificate_authority
    description 'Check if server certificate authority is sha1 signed'

    confine do
      feature(:katello) || feature(:foreman_proxy)
    end

    do_not_whitelist
  end

  def run
    installer_answers = feature(:installer).answers
    server_ca = installer_answers['certs']['server_ca_cert']

    return unless server_ca

    certificate = OpenSSL::X509::Certificate.new(File.read(server_ca))

    msg = <<~MSG
      Server CA certificate signed with sha1 which will break on upgrade.
      Update the server CA certificate with one signed with sha256 or
      stronger then proceed with the upgrade.
    MSG

    assert(certificate.signature_algorithm != 'sha1WithRSAEncryption', msg)
  end
end
