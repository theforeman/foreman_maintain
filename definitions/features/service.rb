class Features::Service < ForemanMaintain::Feature
  metadata do
    label :service
  end

  def handle_services(spinner, action, options = {})
    # options is used to handle "exclude" and "only" and "include" i.e.
    # { :only => ["httpd"] }
    # { :exclude => ["pulp-workers", "tomcat"] }
    # { :include => ["crond"] }
    use_system_service(action, options, spinner)
  end

  def existing_services
    ForemanMaintain.available_features.flat_map(&:services).
      sort.
      inject([]) do |pool, service| # uniq(&:to_s) for ruby 1.8.7
        (pool.last.nil? || !pool.last.matches?(service)) ? pool << service : pool
      end.
      select(&:exist?)
  end

  def filtered_services(options, action = '')
    services = include_unregistered_services(existing_services, options[:include])
    services = filter_services(services, options, action)

    raise 'No services found matching your parameters' unless services.any?
    return services unless options[:reverse]

    Hash[services.sort_by { |k, _| k.to_i }.reverse]
  end

  def action_noun(action)
    action_word_modified(action) + 'ing'
  end

  def action_past_tense(action)
    action_word_modified(action) + 'ed'
  end

  def filter_disabled_services!(action, service_list)
    if %w[start stop restart status].include?(action)
      service_list.select! { |service| !service.respond_to?(:enabled?) || service.enabled? }
    end
    service_list
  end

  def unit_file_available?(name)
    cmd = "systemctl --no-legend --no-pager list-unit-files --type=service #{name} |\
           grep --word-regexp --quiet #{name}"
    exit_status, = execute_with_status(cmd)
    exit_status == 0
  end

  private

  def use_system_service(action, options, spinner)
    options[:reverse] = action == 'stop'
    raise 'Unsupported action detected' unless allowed_action?(action)

    status, failed_services = run_action_on_services(action, options, spinner)

    spinner.update("All services #{action_past_tense(action)}")
    if action == 'status'
      raise "Some services are not running (#{failed_services.join(', ')})" if status > 0

      spinner.update('All services are running')
    end
  end

  def run_action_on_services(action, options, spinner)
    status = 0
    failed_services = []
    filtered_services(options, action).each_value do |group|
      fork_threads_for_services(action, group, spinner).each do |service, status_and_output|
        spinner.update("#{action_noun(action)} #{service}") if action == 'status'
        item_status, output = status_and_output
        formatted = format_status(output, item_status, options)
        puts formatted unless formatted.empty?

        if item_status > 0
          status = item_status
          failed_services << service
        end
      end
    end
    [status, failed_services]
  end

  def fork_threads_for_services(action, services, spinner)
    services_and_statuses = []
    services.each do |service|
      spinner.update("#{action_noun(action)} #{service}") if action != 'status'
      services_and_statuses << [service, Thread.new { service.send(action.to_sym) }]
    end
    services_and_statuses.map! { |service, status| [service, status.value] }
  end

  def format_status(output, exit_code, options)
    status = ''
    if !options[:failing] || exit_code > 0
      if options[:brief]
        status += format_brief_status(exit_code)
      elsif !(output.nil? || output.empty?)
        status += "\n" + output
      end
    end
    status
  end

  def format_brief_status(exit_code)
    result = (exit_code == 0) ? reporter.status_label(:success) : reporter.status_label(:fail)
    padding = reporter.max_length - reporter.last_line.to_s.length - 30
    "#{' ' * padding} #{result}"
  end

  def allowed_action?(action)
    %w[start stop restart status enable disable].include?(action)
  end

  def extend_service_list_with_sockets(service_list, options)
    return service_list unless options[:include_sockets]

    socket_list = service_list.map(&:socket).compact.select(&:exist?)
    service_list + socket_list
  end

  def filter_services(service_list, options, action)
    if options[:only]&.any?
      service_list = service_list.select do |service|
        options[:only].any? { |opt| service.matches?(opt) }
      end
      service_list = include_unregistered_services(service_list, options[:only])
    end

    if options[:exclude]&.any?
      service_list = service_list.reject { |service| options[:exclude].include?(service.name) }
    end

    service_list = extend_service_list_with_sockets(service_list, options)
    service_list = filter_disabled_services!(action, service_list)
    service_list.group_by(&:priority).to_h
  end

  def include_unregistered_services(service_list, services_filter)
    return service_list unless services_filter
    return service_list unless services_filter.any?

    services_filter = services_filter.reject do |obj|
      service_list.any? { |service| service.matches?(obj) }
    end

    unregistered_service_list = services_filter.map do |obj|
      service = if obj.is_a? String
                  system_service(obj)
                elsif valid_sys_service?(obj)
                  obj
                end
      service.exist? ? service : raise("No service found matching your parameter '#{service.name}'")
    end

    service_list.concat(unregistered_service_list)
    service_list
  end

  def action_word_modified(action)
    case action
    when 'status'
      'display'
    when 'enable', 'disable'
      action.chomp('e')
    when 'stop'
      action + 'p'
    else
      action
    end
  end
end
