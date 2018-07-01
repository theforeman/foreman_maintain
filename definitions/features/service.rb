class Features::Service < ForemanMaintain::Feature
  metadata do
    label :service
  end

  def handle_services(spinner, action, options = {})
    # options is used to handle "exclude" and "only" i.e.
    # { :only => ["httpd"] }
    # { :exclude => ["pulp-workers", "tomcat"] }
    if feature(:downstream) && feature(:downstream).less_than_version?('6.3')
      use_katello_service(action, options)
    else
      use_system_service(action, options, spinner)
    end
  end

  def existing_services
    ForemanMaintain.available_features.map(&:services).
      flatten(1).
      sort.
      inject([]) do |pool, service| # uniq(&:to_s) for ruby 1.8.7
        pool.last.nil? || !pool.last.matches?(service) ? pool << service : pool
      end.
      select(&:exist?)
  end

  def filtered_services(options)
    service_list = existing_services
    service_list = filter_services(service_list, options)
    raise 'No services found matching your parameters' unless service_list.any?
    options[:reverse] ? service_list.reverse : service_list
  end

  def action_noun(action)
    action_word_modified(action) + 'ing'
  end

  def action_past_tense(action)
    action_word_modified(action) + 'ed'
  end

  def find_service_status(service)
    command = service_command('status', service)
    execute?(command)
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

    filtered_services(options).each do |service|
      spinner.update("#{action_noun(action)} #{service}")
      item_status, output = service.send(action.to_sym)

      formatted = format_status(output, item_status, options)
      puts formatted unless formatted.empty?

      if item_status > 0
        status = item_status
        failed_services << service
      end
    end
    [status, failed_services]
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
    result = exit_code == 0 ? reporter.status_label(:success) : reporter.status_label(:fail)
    padding = reporter.max_length - reporter.last_line.to_s.length - 30
    "#{' ' * padding} #{result}"
  end

  def allowed_action?(action)
    %w[start stop restart status enable disable].include?(action)
  end

  def filter_services(service_list, options)
    if options[:only] && options[:only].any?
      service_list = service_list.select do |service|
        options[:only].any? { |opt| service.matches?(opt) }
      end
    end
    if options[:exclude] && options[:exclude].any?
      service_list = service_list.reject { |service| options[:exclude].include?(service.name) }
    end
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

  def use_katello_service(action, options)
    if %w[enable disable].include?(action)
      raise 'Service enable and disable are only supported in Satellite 6.3+'
    end

    command = "katello-service #{action} "

    # katello-service in 6.1 does not support --only
    if feature(:downstream).less_than_version?('6.2')
      excluded_services = exclude_services_only(options)
      command += "--exclude #{excluded_services.join(',')}" if excluded_services.any?
    else
      command += katello_service_filters(options)
    end

    run_katello_service(command)
  end

  def run_katello_service(command)
    puts "Services are handled by katello-service in Satellite versions 6.2 and earlier. \n" \
         "Flags --brief or --failing will be ignored if present. Redirecting to: \n#{command}\n"
    puts execute(command)
  end

  def exclude_services_only(options)
    existing_services - filtered_services(options)
  end

  def katello_service_filters(options)
    filters = ''
    if options[:exclude] && options[:exclude].any?
      filters += "--exclude #{options[:exclude].join(',')}"
    end
    if options[:only] && options[:only].any?
      filters += "--only #{options[:only].join(',')}"
    end
    filters
  end
end
