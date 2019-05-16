require 'net/http'
require 'json'

class Features::Instance < ForemanMaintain::Feature
  metadata do
    label :instance
  end

  attr_reader :last_ping_failing_services, :last_ping_status, :last_ping_result

  def foreman_proxy_product_name
    feature(:downstream) ? 'Capsule' : 'Foreman Proxy'
  end

  def server_product_name
    if feature(:downstream)
      'Satellite'
    elsif feature(:katello)
      'Katello'
    else
      'Foreman'
    end
  end

  def external_proxy?
    !!(feature(:foreman_proxy) && !feature(:foreman_server))
  end

  def product_name
    if external_proxy?
      foreman_proxy_product_name
    else
      server_product_name
    end
  end

  def database_remote?(feature)
    !!feature(feature) && !feature(feature).local?
  end

  def database_local?(feature)
    !!feature(feature) && feature(feature).local?
  end

  def postgresql_local?
    database_local?(:candlepin_database) || database_local?(:foreman_database)
  end

  def foreman_proxy_with_content?
    feature(:foreman_proxy) && feature(:foreman_proxy).with_content? && !feature(:katello)
  end

  def ping?
    if feature(:katello)
      katello_ping
    elsif external_proxy?
      proxy_ping
    else
      foreman_ping
    end
    last_ping_result
  end

  def server_connection
    net = Net::HTTP.new(ForemanMaintain.config.foreman_url, ForemanMaintain.config.foreman_port)
    net.use_ssl = true
    net
  end

  private

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def katello_ping
    res = server_connection.get('/katello/api/ping')
    logger.debug('Called /katello/api/ping')
    logger.debug("Response: #{res.code}, #{res.body}")
    response = JSON.parse(res.body)
    if res.code != '200' # foreman error
      set_ping_result(false, response.message, nil)
    else # valid response
      failing_components = pick_failing_components(response['services'])
      if failing_components.empty? # all okay
        set_ping_result(true, 'Success', nil)
      else # some components not okay
        set_ping_result(false,
                        "Some components are failing: #{failing_components.join(', ')}",
                        component_services(failing_components))
      end
    end
  rescue StandardError => e # server error, server down
    set_ping_result(false, "Couldn't connect to the server: #{e.message}", nil)
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def foreman_ping
    res = server_connection.get('/apidoc/apipie_checksum')
    logger.debug('Called /apidoc/apipie_checksum')
    logger.debug("Response: #{res.code}, #{res.body}")
    if res.code != '200' # foreman error
      set_ping_result(false, response.message, nil)
    else # valid response
      set_ping_result(true, 'Success', nil)
    end
  rescue StandardError => e # server error, server down
    set_ping_result(false, "Couldn't connect to the server: #{e.message}", nil)
  end

  def proxy_ping
    feature(:foreman_proxy).features
    set_ping_result(true, 'Success', nil)
  rescue StandardError => e # server error, proxy down
    set_ping_result(false, "Couldn't connect to the proxy: #{e.message}", nil)
  end

  def pick_failing_components(components)
    components.inject([]) do |failing, (name, data)|
      data['status'] != 'ok' ? failing << name : failing
    end
  end

  def set_ping_result(result, message, failing_services)
    @last_ping_status = message
    @last_ping_failing_services = failing_services
    @last_ping_result = result
  end

  def installer_scenario_answers
    feature(:installer).answers
  end

  def component_features_map
    {
      'candlepin_auth' =>  %w[candlepin candlepin_database],
      'candlepin' => %w[candlepin candlepin_database],
      'pulp_auth' => %w[pulp mongo],
      'pulp' => %w[pulp mongo],
      'foreman_tasks' => %w[foreman_tasks]
    }
  end

  def component_services(components)
    components = [components].flatten(1)
    cf_map = component_features_map
    # map ping components to features
    features = components.map { |component| cf_map[component] }.flatten.uniq
    # map features to existing services
    features.map { |name| feature(name.to_sym).services }.flatten.uniq.select(&:exist?)
  end
end
