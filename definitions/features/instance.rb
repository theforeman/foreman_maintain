require 'net/http'
require 'json'

class Features::Instance < ForemanMaintain::Feature
  metadata do
    label :instance
  end

  def foreman_proxy_product_name
    feature(:capsule) ? 'Capsule' : 'Foreman Proxy'
  end

  def server_product_name
    if feature(:satellite)
      'Satellite'
    elsif feature(:katello)
      'Katello'
    else
      'Foreman'
    end
  end

  def product_name
    if feature(:foreman_proxy) && !feature(:foreman_proxy).internal?
      foreman_proxy_product_name
    else
      server_product_name
    end
  end

  def project_support_entity
    if downstream
      'Red Hat Technical Support'
    else
      'Foreman Community Support'
    end
  end

  def database_remote?(feature)
    !!feature(feature) && !feature(feature).local?
  end

  def database_local?(feature)
    !!feature(feature) && feature(feature).local?
  end

  def postgresql_local?
    database_local?(:candlepin_database) ||
      database_local?(:foreman_database) ||
      database_local?(:pulpcore_database) ||
      database_local?(:container_gateway_database)
  end

  def foreman_proxy_with_content?
    feature(:foreman_proxy)&.with_content? && !feature(:katello)
  end

  def downstream
    @downstream ||= (feature(:satellite) || feature(:capsule))
  end

  def ping
    if feature(:katello)
      katello_ping
    elsif feature(:foreman_proxy) && !feature(:foreman_proxy).internal?
      proxy_ping
    else
      foreman_ping
    end
  end

  def server_connection_ca_file
    @server_connection_ca_file ||= feature(:installer).answers['foreman']['server_ssl_chain']
  end

  def server_connection
    net = Net::HTTP.new(ForemanMaintain.config.foreman_url, ForemanMaintain.config.foreman_port)
    net.ca_file = server_connection_ca_file
    net.use_ssl = true
    net
  end

  def pulp
    feature(:pulpcore)
  end

  def firewall
    feature(:nftables) || feature(:iptables)
  end

  def upstream_install
    feature(:foreman_install) || feature(:katello_install)
  end

  def current_version
    version = if feature(:instance).downstream
                feature(:instance).downstream.current_version
              else
                feature(:foreman_install).current_version
              end

    version.to_s[/^\d+\.\d+\.\d+/]
  end

  def current_major_version
    current_version.to_s[/^\d+\.\d+/]
  end

  def target_version
    if feature(:instance).downstream
      Features::Satellite.new.target_version
    else
      Features::ForemanInstall.new.target_version
    end
  end

  private

  # rubocop:disable Metrics/AbcSize
  def katello_ping
    res = server_connection.get('/katello/api/ping')
    logger.debug('Called /katello/api/ping')
    logger.debug("Response: #{res.code}, #{res.body}")
    response = JSON.parse(res.body)
    if res.code != '200' # foreman error
      result = create_response(false, response['message'] || response['displayMessage'])
    else # valid response
      failing_components = pick_failing_components(response['services'])
      result = if failing_components.empty? # all okay
                 create_response(true, 'Success')
               else # some components not okay
                 create_response(false,
                   "Some components are failing: #{failing_components.join(', ')}",
                   component_services(failing_components))
               end
    end
    result
  rescue StandardError => e # server error, server down
    create_response(false, "Couldn't connect to the server: #{e.message}")
  end
  # rubocop:enable Metrics/AbcSize

  def foreman_ping
    res = server_connection.get('/apidoc/apipie_checksum')
    logger.debug('Called /apidoc/apipie_checksum')
    logger.debug("Response: #{res.code}, #{res.body}")

    if res.code != '200' # foreman error
      create_response(false, response.message)
    else # valid response
      create_response(true, 'Success')
    end
  rescue StandardError => e # server error, server down
    create_response(false, "Couldn't connect to the server: #{e.message}")
  end

  def proxy_ping
    feature(:foreman_proxy).features
    create_response(true, 'Success')
  rescue StandardError => e # server error, proxy down
    create_response(false, "Couldn't connect to the proxy: #{e.message}")
  end

  def pick_failing_components(components)
    components.each_with_object([]) do |(name, data), failing|
      failing << name unless data['status'] == 'ok'
    end
  end

  def create_response(succeeded, message, failing_services = nil)
    data = {}
    data[:failing_services] = failing_services
    ForemanMaintain::Utils::Response.new(succeeded, message, :data => data)
  end

  def installer_scenario_answers
    feature(:installer).answers
  end

  def component_features_map
    {
      'candlepin_auth' => %w[candlepin candlepin_database],
      'candlepin_events' => %w[candlepin candlepin_database],
      'candlepin' => %w[candlepin candlepin_database],
      'pulp3' => %w[pulpcore pulpcore_database],
      'pulp3_content' => %w[pulpcore pulpcore_database],
      'foreman_tasks' => %w[foreman_tasks],
      'katello_events' => %w[katello],
    }
  end

  def component_services(components)
    components = Array(components)
    cf_map = component_features_map
    # map ping components to features
    features = components.map { |component| cf_map[component] }.flatten.uniq.compact
    # map features to existing services
    services_of_features = features.map do |name|
      feature(name.to_sym) ? feature(name.to_sym).services : []
    end
    services_of_features.flatten.uniq.select(&:exist?)
  end
end
