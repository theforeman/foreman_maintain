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

  private

  def use_system_service(action, options, spinner)
    options[:reverse] = action == 'stop'
    raise 'Unsupported action detected' unless allowed_action?(action)

    status = 0
    failed_services = []

    filtered_services(options).each do |service|
      spinner.update("#{action_noun(action)} #{service}")
      item_status, output = service.send(action.to_sym)

      if item_status > 0
        status = item_status
        failed_services << service
      end

      puts format_status(output)
    end

    spinner.update("All services #{action_past_tense(action)}")
    raise "Some services are not running (#{failed_services.join(', ')})" if status > 0
  end

  def format_status(output)
    status = "\n"
    status += output if !output.nil? && !output.empty?
    status
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
    puts 'Services are handled by katello-service in Satellite versions 6.2 and earlier. ' \
         "Redirecting to: \n#{command}\n"
    puts execute(command)
  end

  def exclude_services_only(options)
    existing_services - filtered_services(options)
  end

  def katello_service_filters(options)
    filters = ''
    filters += "--exclude #{options[:exclude]}" if options[:exclude] && options[:exclude].any?
    filters += "--only #{options[:only]}" if options[:only] && options[:only].any?
    filters
  end
end
