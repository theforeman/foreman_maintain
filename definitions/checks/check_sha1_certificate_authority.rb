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

    begin
      certificates = load_fullchain(server_ca)
    rescue OpenSSL::X509::CertificateError
      assert(false, "Error reading server CA certificate #{server_ca}.")
    else
      msg = <<~MSG
        Server CA certificate #{server_ca} signed with sha1 which will break on upgrade.
        Update the server CA certificate with one signed with sha256 or
        stronger then proceed with the upgrade.
      MSG

      assert(
        certificates.all? { |cert| cert.signature_algorithm != 'sha1WithRSAEncryption' },
        msg
      )
    end
  end

  def load_fullchain(bundle_pem)
    if OpenSSL::X509::Certificate.respond_to?(:load_file)
      OpenSSL::X509::Certificate.load_file(bundle_pem)
    else
      # Can be removed when only Ruby with load_file support is supported
      File.binread(bundle_pem).
        lines.
        slice_after(/END CERTIFICATE/).
        map { |pem| OpenSSL::X509::Certificate.new(pem.join) }
    end
  end
end
