class Features::Timer < ForemanMaintain::Feature
  metadata do
    label :timer
  end

  def handle_timers(spinner, action, options = {})
    # options is used to handle "exclude" and "only" i.e.
    # { :only => ["httpd"] }
    # { :exclude => ["pulp-workers", "tomcat"] }
    use_system_timer(action, options, spinner)
  end

  def existing_timers
    ForemanMaintain.available_features.flat_map(&:timers).
      sort.uniq(&:to_s).
      select(&:exist?)
  end

  def filtered_timers(options, action = '')
    timers = filter_timers(existing_timers, options, action)

    raise 'No timers found matching your parameters' unless timers.any?
    return timers unless options[:reverse]

    Hash[timers.sort_by { |k, _| k.to_i }.reverse]
  end

  def action_noun(action)
    action_word_modified(action) + 'ing'
  end

  def action_past_tense(action)
    action_word_modified(action) + 'ed'
  end

  def filter_disabled_timers!(action, timer_list)
    if %w[start stop restart status].include?(action)
      timer_list.select! { |timer| !timer.respond_to?(:enabled?) || timer.enabled? }
    end
    timer_list
  end

  private

  def use_system_timer(action, options, spinner)
    options[:reverse] = action == 'stop'
    raise 'Unsupported action detected' unless allowed_action?(action)

    status, failed_timers = run_action_on_timers(action, options, spinner)

    spinner.update("All timers #{action_past_tense(action)}")
    if action == 'status'
      raise "Some timers are not running (#{failed_timers.join(', ')})" if status > 0

      spinner.update('All timers are running')
    end
  end

  def run_action_on_timers(action, options, spinner)
    status = 0
    failed_timers = []
    filtered_timers(options, action).each_value do |group|
      fork_threads_for_timers(action, group, spinner).each do |timer, status_and_output|
        spinner.update("#{action_noun(action)} #{timer}") if action == 'status'
        item_status, output = status_and_output
        formatted = format_status(output, item_status, options)
        puts formatted unless formatted.empty?

        if item_status > 0
          status = item_status
          failed_timers << timer
        end
      end
    end
    [status, failed_timers]
  end

  def fork_threads_for_timers(action, timers, spinner)
    timers_and_statuses = []
    timers.each do |timer|
      spinner.update("#{action_noun(action)} #{timer}") if action != 'status'
      timers_and_statuses << [timer, Thread.new { timer.send(action.to_sym) }]
    end
    timers_and_statuses.map! { |timer, status| [timer, status.value] }
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

  def filter_timers(timer_list, options, action)
    if options[:only]&.any?
      timer_list = timer_list.select do |timer|
        options[:only].any? { |opt| timer.matches?(opt) }
      end
    end

    if options[:exclude]&.any?
      timer_list = timer_list.reject { |timer| options[:exclude].include?(timer.name) }
    end

    timer_list = filter_disabled_timers!(action, timer_list)
    timer_list.group_by(&:priority).to_h
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
