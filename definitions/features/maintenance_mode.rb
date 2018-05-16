class Features::MaintenanceMode < ForemanMaintain::Feature
  metadata do
    label :maintenance_mode
    confine do
      feature(:service)
    end
  end

  def cron_service
    # TODO: For debian, add cron as service
    'crond'
  end

  def perform_action(type_for_action, action_name)
    case type_for_action
    when :iptables
      action_on_iptables(action_name)
    when :cron
      action_for_cron_service(action_name)
    when :maintenance_file
      action_on_maintenance_file(action_name)
    else
      raise "Unexpected argument #{action_name}"
    end
  end

  def maintenance_file
    ForemanMaintain.config.maintenance_file
  end

  def maintenance_file_present?
    file_exists?(maintenance_file)
  end

  private

  def action_for_cron_service(action_name)
    feature(:service).perform_action_on_local_service(action_name, cron_service)
  end

  def action_on_iptables(action_name)
    case action_name
    when 'add_chain'
      custom_iptables_chain('FOREMAN_MAINTAIN',
                            ['-i lo -j ACCEPT',
                             '-p tcp --dport 443 -j REJECT'])
    when 'remove_chain'
      del_custom_iptables_chain('FOREMAN_MAINTAIN')
    else
      raise "Unexpected argument #{action_name}"
    end
  end

  def action_on_maintenance_file(action_name)
    case action_name
    when 'create'
      File.new(maintenance_file, 'w+') unless maintenance_file_present?
    when 'remove'
      File.delete(maintenance_file) if maintenance_file_present?
    end
  end

  def custom_iptables_chain(name, rules)
    # if the chain already exists, we assume it was set before: we're not touching
    # it again
    return if execute?("iptables -L #{name}")
    execute!("iptables -N #{name}")
    rules.each do |rule|
      execute!("iptables -A #{name} #{rule}")
    end
    execute!("iptables -I INPUT -j #{name}")
  end

  def del_custom_iptables_chain(name)
    return unless execute?("iptables -L #{name}") # the chain is already gone
    if execute?("iptables -L INPUT | tail -n +3 | grep '^#{name} '")
      execute!("iptables -D INPUT -j #{name}")
    end
    execute!("iptables -F #{name}")
    execute!("iptables -X #{name}")
  end
end
