class Features::ForemanProxy < ForemanMaintain::Feature
  metadata do
    label :foreman_proxy
    confine do
      find_package('foreman-proxy')
    end
  end

  FOREMAN_PROXY_SETTINGS_PATHS = ['/etc/foreman-proxy/settings.yml',
                                  '/usr/local/etc/foreman-proxy/settings.yml'].freeze

  FOREMAN_PROXY_DHCP_YML_PATHS = ['/etc/foreman-proxy/settings.d/dhcp.yml',
                                  '/usr/local/etc/foreman-proxy/settings.d/dhcp.yml'].freeze

  FOREMAN_PROXY_TFTP_YML_PATHS = ['/etc/foreman-proxy/settings.d/tftp.yml',
                                  '/usr/local/etc/foreman-proxy/settings.d/tftp.yml'].freeze

  def valid_dhcp_configs?
    dhcp_req_pass? && !syntax_error_exists?
  end

  def with_content?
    !!feature(:instance).pulp
  end

  def dhcpd_conf_exist?
    file_exists?(dhcpd_config_file)
  end

  def services
    [
      system_service('smart_proxy_dynflow_core', 20),
      system_service('foreman-proxy', 40)
    ]
  end

  def features
    # TODO: handle failures
    @features ||= run_curl_cmd("#{curl_cmd}/features").result
    @features = [] if @features.is_a?(String)
    @features
  end

  def refresh_features
    @features = nil
    features
  end

  def internal?
    !!feature(:foreman_server)
  end

  def default_config_files
    [
      '/etc/foreman-proxy',
      '/usr/share/foreman-proxy/.ssh',
      '/var/lib/foreman-proxy/ssh',
      '/etc/smart_proxy_dynflow_core/settings.yml',
      '/etc/sudoers.d/foreman-proxy',
      settings_file
    ]
  end

  def config_files(for_features = ['all'])
    configs = default_config_files
    backup_features = backup_features(for_features)

    configs.push(certs_tar) if certs_tar

    configs.push('/var/lib/tftpboot') if backup_features.include?('tftp')
    configs += ['/var/named/', '/etc/named*'] if backup_features.include?('dns')
    if backup_features.include?('dhcp') && dhcp_isc_provider?
      configs += ['/var/lib/dhcpd', File.dirname(dhcpd_config_file)]
    end
    configs.push('/usr/share/xml/scap') if backup_features.include?('openscap')
    configs
  end

  def config_files_to_exclude(_for_features = ['all'])
    []
  end

  def content_module
    return @content_module if @content_module_detected

    @content_module_detected = true
    answer = feature(:installer).answers.find do |_, config|
      config.is_a?(Hash) && config.key?(certs_param_name[:param_key])
    end
    @content_module = answer.nil? ? certs_param_name[:param_section] : answer.first
    logger.debug("foreman proxy content module detected: #{@content_module}")
    @content_module
  end

  def certs_param_name
    if check_min_version('foreman', '1.21')
      return { :param_section => 'certs', :param_key => 'tar_file' }
    end

    { :param_section => 'foreman_proxy_content', :param_key => 'certs_tar' }
  end

  def certs_tar
    if content_module
      feature(:installer).answers.fetch(content_module, {})[certs_param_name[:param_key]]
    end
  end

  def settings_file
    @settings_file ||= lookup_into(FOREMAN_PROXY_SETTINGS_PATHS)
  end

  def proxy_settings
    @proxy_settings ||= load_proxy_settings
  end

  def dhcpd_config_file
    @dhcpd_config_file ||= lookup_dhcpd_config_file
  end

  def tftp_root_directory
    @tftp_root_directory ||= lookup_tftp_root_directory
  end

  def dhcp_isc_provider?
    configs_from_dhcp_yml[:use_provider] == 'dhcp_isc'
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
    ssl_cert = proxy_settings[:foreman_ssl_cert] || proxy_settings[:ssl_certificate]
    ssl_key = proxy_settings[:foreman_ssl_key] || proxy_settings[:ssl_private_key]
    ssl_ca = proxy_settings[:foreman_ssl_ca] || proxy_settings[:ssl_ca_file]

    cmd = "curl -w '\n%{http_code}' -s "
    cmd += format_shell_args('--cert' => ssl_cert, '--key' => ssl_key, '--cacert' => ssl_ca)
    cmd += " https://$(hostname):#{proxy_settings[:https_port]}"
    cmd
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
    cmd = "dhcpd -t -cf #{dhcpd_config_file}"
    output = execute(cmd)
    is_error = output.include?('Configuration file errors encountered')
    if is_error
      puts "\nFound syntax error in file #{dhcpd_config_file}:"
      puts output
    end
    is_error
  end

  def load_proxy_settings
    if settings_file
      @proxy_settings = yaml_load(settings_file)
    else
      raise "Couldn't find settings file at #{FOREMAN_PROXY_SETTINGS_PATHS.join(', ')}"
    end
  end

  def lookup_dhcpd_config_file
    dhcpd_config_file = lookup_using_dhcp_yml
    raise "Couldn't find DHCP Configuration file" if dhcpd_config_file.nil?

    dhcpd_config_file
  end

  def dhcp_yml_path
    dhcp_path = lookup_into(FOREMAN_PROXY_DHCP_YML_PATHS)
    raise "Couldn't find dhcp.yml file under foreman-proxy" unless dhcp_path

    dhcp_path
  end

  def configs_from_dhcp_yml
    @configs_from_dhcp_yml ||= yaml_load(dhcp_yml_path)
  end

  def lookup_using_dhcp_yml
    if configs_from_dhcp_yml.key?(:dhcp_config)
      return configs_from_dhcp_yml[:dhcp_config]
    elsif configs_from_dhcp_yml.key?(:use_provider)
      settings_d_dir = File.dirname(dhcp_yml_path)
      dhcp_provider_fpath = File.join(settings_d_dir, "#{configs_from_dhcp_yml[:use_provider]}.yml")
      dhcp_provider_configs = yaml_load(dhcp_provider_fpath)
      return dhcp_provider_configs[:config] if dhcp_provider_configs.key?(:config)
    else
      raise "Couldn't find DHCP Configurations in #{dhcp_yml_path}"
    end
  end

  def lookup_tftp_root_directory
    tftp_yml_path = lookup_into(FOREMAN_PROXY_TFTP_YML_PATHS)
    raise "Couldn't find tftp.yml file under foreman-proxy" unless tftp_yml_path

    yaml_load(tftp_yml_path)[:tftproot]
  end

  def yaml_load(path)
    YAML.load_file(path) || {}
  end

  def lookup_into(file_paths)
    file_paths.find { |file_path| file_exists?(file_path) }
  end
end
