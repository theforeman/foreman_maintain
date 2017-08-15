class Features::KatelloService < ForemanMaintain::Feature
  metadata do
    label :katello_service
  end

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
        spinner.update 'Starting the katello services..'
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
      spinner.update 'Starting the katello services..'
      execute!("katello-service start #{filters}")
    end
  end

  private

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
