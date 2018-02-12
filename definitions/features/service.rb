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
      options[:reverse] = action == 'stop'

      filtered_services(options).each do |service|
        spinner.update("#{action_noun(action)} #{service}")
        perform_action_on_service(action, service)
      end

      spinner.update("All services #{action_past_tense(action)}")
    end
  end

  def list_services(service_list)
    service_list = service_list.join(', ')
    puts "#{service_list}\n"
  end

  def get_services_from_features(features)
    features.map(&:services).
      inject(&:merge).
      sort_by { |_, value| value }.
      map { |service| service[0] }
  end

  def existing_services
    service_list = get_services_from_features(available_features)
    service_list.select { |service| service_exists?(service) }
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

  def available_features
    @available_features || ForemanMaintain.available_features
  end

  def filter_services(service_list, options)
    service_list &= options[:only] if options[:only] && options[:only].any?
    service_list -= options[:exclude] if options[:exclude] && options[:exclude].any?
    service_list
  end

  def perform_action_on_service(action, service)
    command = "systemctl #{action} #{service}"
    if action == 'status'
      status = execute(command)
      puts "\n\n#{status}\n\n"
    else
      execute!(command)
    end
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
