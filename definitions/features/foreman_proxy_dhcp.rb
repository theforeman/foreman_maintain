class Features::ForemanProxyDhcp < ForemanMaintain::Feature
  metadata do
    label :foreman_proxy_dhcp

    confine do
      file_exists?('/etc/dhcp/dhcpd.conf') && feature(:foreman_proxy)
    end
  end

  attr_reader :dhcpd_conf_file, :dhcp_api_resource

  def initialize
    @dhcpd_conf_file = '/etc/dhcp/dhcpd.conf'
  end

  def valid_dhcp_configs?
    dhcp_req_pass? && !syntax_error_exists?
  end

  def subnet_list
    success = dhcp_api_resource.get do |response, _request, _result|
      case response.code
      when 200
        result = JSON.pretty_generate(JSON.parse(response))
        puts "\n#{result}"
        true
      else
        puts "\nStatus - #{response.code}. Response - #{response.body}."
        false
      end
    end
    success
  end

  def list_reservations(subnet)
    resp = dhcp_api_resource["/#{subnet}"].get { |response, _request, _result| response }
    handle_api_response(resp, true)
  end

  def add_reservation(subnet, ip, mac_address, name)
    payload = { :ip => ip, :mac => mac_address, :name => name }
    resp = dhcp_api_resource["/#{subnet}"].post(
      payload, :content_type => :json, :accept => :json
    ) { |response, _request, _result| response }
    handle_api_response(resp)
  end

  def delete_reservation(subnet, ip)
    delete_api = api_deprecated_for_delete? ? "/#{subnet}/ip/#{ip}" : "/#{subnet}/#{ip}"
    resp = dhcp_api_resource[delete_api].delete { |response, _request, _result| response }
    handle_api_response(resp)
  end

  def dhcp_api_resource
    @dhcp_api_resource ||= feature(:foreman_proxy).dhcp_api_resource
  end

  private

  def api_deprecated_for_delete?
    check_min_version('foreman-proxy', '1.15.0')
  end

  def handle_api_response(resp, json_parsing_req = false)
    case resp.code
    when 200
      result = json_parsing_req ? JSON.pretty_generate(JSON.parse(resp)) : resp
      puts result
    else
      raise ForemanMaintain::Error::Fail, "#{resp.body}. Status - #{resp.code}"
    end
  end

  def dhcp_req_pass?
    subnet_list
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
