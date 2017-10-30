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

  private

  def dhcp_curl_cmd
    "curl -w '\n%{http_code}' -slient -ks --cert #{cert_path}/client_cert.pem \
      --key #{cert_path}/client_key.pem \
      --cacert #{cert_path}/proxy_ca.pem https://$(hostname):9090/dhcp"
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
      http_line.split(curl_http_status.to_s).last.strip
    end
  end

  def run_dhcp_curl
    curl_resp = execute(dhcp_curl_cmd)
    array_output = curl_resp.split(/\r\n/)
    result_array = array_output.last.split(/\n/)
    curl_http_status = result_array.delete_at(result_array.length - 1).strip.to_i
    curl_http_resp = parse_json(result_array.join(''))
    ForemanMaintain::Utils::CurlResponse.new(
      curl_http_resp,
      curl_http_status,
      find_http_error_msg(array_output, curl_http_status)
    )
  end

  def dhcp_req_pass?
    dhcp_curl_resp = run_dhcp_curl
    success = true
    if dhcp_curl_resp.http_code.eql?(200)
      if dhcp_curl_resp.result.empty?
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
