class Features::ForemanProxy < ForemanMaintain::Feature
  metadata do
    label :foreman_proxy

    confine do
      ForemanMaintain.config.foreman_proxy_settings_path &&
        ForemanMaintain::Utils::ForemanProxySettings.instance.ssl_certs_exists?
    end
  end

  attr_reader :settings, :base_url, :openssl_cert_options

  def dhcp_api_resource
    RestClient::Resource.new("#{base_url}/dhcp", openssl_cert_options)
  end

  def settings
    @settings ||= ForemanMaintain::Utils::ForemanProxySettings.instance
  end

  def base_url
    @base_url ||= construct_foreman_proxy_url
  end

  def openssl_cert_options
    @openssl_cert_options ||= openssl_certs_hash
  end

  private

  def construct_foreman_proxy_url
    URI.parse("#{settings.foreman_url}:#{settings.proxy_port}").to_s
  end

  def openssl_certs_hash
    return {} unless settings.ssl_certs_exists?
    {
      :ssl_client_cert => OpenSSL::X509::Certificate.new(File.read(settings.foreman_ssl_cert)),
      :ssl_client_key => OpenSSL::PKey::RSA.new(File.read(settings.foreman_ssl_key)),
      :ssl_ca_file => settings.foreman_ssl_ca,
      :verify_ssl => OpenSSL::SSL::VERIFY_PEER
    }
  end
end
