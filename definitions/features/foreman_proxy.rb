class Features::ForemanProxy < ForemanMaintain::Feature
  metadata do
    label :foreman_proxy
    confine do
      find_package('foreman-proxy')
    end
  end

  attr_reader :dhcpd_conf_file, :cert_path

  def initialize
    @dhcpd_conf_file = '/etc/dhcp/dhcpd.conf'
    @cert_path = ForemanMaintain.config.foreman_proxy_cert_path
  end

  def valid_dhcp_configs?
    dhcp_req_pass? && !syntax_error_exists?
  end

  def services
    {
      'foreman-proxy'            => 20,
      'smart_proxy_dynflow_core' => 20
    }
  end

  def features
    # TODO: handle failures
    run_curl_cmd("#{curl_cmd}/features").result
  end

  def internal?
    !!feature(:foreman_server)
  end

  def config_files(for_features = ['all'])
    configs = [
      '/etc/foreman-proxy',
      '/usr/share/foreman-proxy/.ssh/',
      '/etc/smart_proxy_dynflow_core/settings.yml',
      '/etc/sudoers.d/foreman-proxy'
    ]
    backup_features = backup_features(for_features)

    configs.push(certs_tar) if certs_tar

    configs.push('/var/lib/tftpboot') if backup_features.include?('tftp')
    configs += ['/var/named/', '/etc/named*'] if backup_features.include?('dns')
    configs += ['/var/lib/dhcpd', '/etc/dhcp'] if backup_features.include?('dhcp')
    configs.push('/usr/share/xml/scap') if backup_features.include?('openscap')
    configs
  end

  def content_module
    return @content_module if @content_module_detected
    @content_module_detected = true
    answer = feature(:installer).answers.find do |_, config|
      config.is_a?(Hash) && config.key?('certs_tar')
    end
    @content_module = answer.nil? ? 'foreman_proxy_content' : answer.first
    logger.debug("foreman proxy content module detected: #{@content_module}")
    @content_module
  end

  def certs_tar
    feature(:installer).answers[content_module]['certs_tar'] if content_module
  end

  private

  def backup_features(for_features)
    full_features = features
    backup_features = for_features.include?('all') ? full_features : (full_features & for_features)
    logger.info("Proxy features: #{full_features}")
    logger.info("Proxy features to backup: #{backup_features}")
    backup_features
  end

  def curl_cmd
    "curl -w '\n%{http_code}' --silent -ks --cert #{cert_path}/client_cert.pem \
      --key #{cert_path}/client_key.pem \
      --cacert #{cert_path}/proxy_ca.pem https://$(hostname):9090"
  end

  def dhcp_curl_cmd
    "#{curl_cmd}/dhcp"
  end

  def find_http_error_msg(array_output, curl_http_status)
    if curl_http_status == 0
      'No valid HTTP response (Connection failed)'
    else
      http_line = ''
      array_output.each do |str|
        next unless str.include?('HTTP')
        http_line = str
      end
      msg = http_line.split(curl_http_status.to_s).last
      msg = msg.strip unless msg.nil?
      msg
    end
  end

  def run_curl_cmd(cmd)
    # TODO: consider Net::HTTP instead of curl
    curl_resp = execute(cmd)
    array_output = curl_resp.split(/\r?\n/)
    status_str = array_output.last
    curl_http_status = (status_str ? status_str.strip : status_str).to_i
    curl_http_resp = parse_json(array_output[0])
    ForemanMaintain::Utils::CurlResponse.new(
      curl_http_resp,
      curl_http_status,
      find_http_error_msg(array_output, curl_http_status)
    )
  end

  def dhcp_req_pass?
    dhcp_curl_resp = run_curl_cmd(dhcp_curl_cmd)
    success = true
    if dhcp_curl_resp.http_code.eql?(200)
      if dhcp_curl_resp.result.to_s.empty?
        success = false
        puts "Verify DHCP Settings. Response: #{dhcp_curl_resp.result.inspect}"
      end
    else
      success = false
      puts dhcp_curl_resp.error_msg
    end
    success
  end

  def syntax_error_exists?
    cmd = "dhcpd -t -cf #{dhcpd_conf_file}"
    output = execute(cmd)
    is_error = output.include?('Configuration file errors encountered')
    if is_error
      puts "\nFound syntax error in file #{dhcpd_conf_file}:"
      puts output
    end
    is_error
  end
end
