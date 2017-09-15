class Features::KatelloService < ForemanMaintain::Feature
  metadata do
    label :katello_service
  end

  RETRIES_FOR_SERVICES_RESTART = 5
  PING_RETRY_INTERVAL = 30

  def make_stop(spinner, options = {})
    services = find_services_for_only_filter(running_services, options)
    if services.empty?
      spinner.update 'No katello service running'
      yield
    else
      begin
        filters = "--only #{services.join(',')}"
        spinner.update 'Stopping katello running services..'
        execute!("katello-service stop #{filters}")
        yield
      ensure
        spinner.update 'Starting katello services..'
        execute("katello-service start #{filters}")
      end
    end
  end

  def make_start(spinner, options = {})
    services = find_services_for_only_filter(stopped_services, options)
    if services.empty?
      spinner.update 'No katello service to start'
    else
      filters = "--only #{services.join(',')}"
      spinner.update 'Starting katello services..'
      execute!("katello-service start #{filters}")
    end
  end

  def restart(options = {})
    if options[:only] || options[:exclude]
      filters = construct_filters_for_restart(options)
      execute!("katello-service restart #{filters}")
    else
      execute!('katello-service restart')
    end
  end

  def hammer_ping_retry(spinner)
    RETRIES_FOR_SERVICES_RESTART.times do |retry_count|
      msg = "Try #{retry_count + 1}/#{RETRIES_FOR_SERVICES_RESTART}: checking status by hammer ping"
      spinner.update msg
      result = feature(:hammer).hammer_ping_cmd
      if result[:success]
        spinner.update 'All services are running.'
        break
      elsif retry_count < (RETRIES_FOR_SERVICES_RESTART - 1)
        apply_sleep_before_retry(spinner, result)
      end
    end
  rescue StandardError => e
    logger.error e.message
  end

  private

  def apply_sleep_before_retry(spinner, result)
    puts "\n#{result[:message]}"
    spinner.update "Waiting #{PING_RETRY_INTERVAL} seconds before retry."
    sleep PING_RETRY_INTERVAL
  end

  def construct_filters_for_restart(options)
    filters = ''
    if options[:only]
      filters += "--only #{options[:only].join(',')}" unless options[:only].empty?
    end
    if options[:exclude]
      filters += "--exclude #{options[:exclude].join(',')}" unless options[:exclude].empty?
    end
    filters
  end

  def find_services_for_only_filter(curr_services, options)
    defaults = { :only => [], :exclude => [] }
    options = defaults.merge(options)
    curr_services &= options[:only] unless options[:only].empty?
    curr_services - options[:exclude]
  end

  def running_services
    find_services_by_state(" -w 'running'")
  end

  def stopped_services
    find_services_by_state(" -w 'dead'")
  end

  def find_services_by_state(state)
    katello_service_names = execute("katello-service list|awk '{print $1}'").split(/\n/)
    services_by_state = execute("systemctl --all |grep #{state}|awk '{print $1}'").split(/\n/)
    (katello_service_names & services_by_state).map { |s| s.gsub('.service', '') }
  end
end
