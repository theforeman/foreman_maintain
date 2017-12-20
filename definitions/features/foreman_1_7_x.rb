class Features::Foreman_1_7_x < ForemanMaintain::Feature
  metadata do
    label :foreman

    confine do
      check_min_version('foreman', '1.7')
    end
  end

  def maintenance_mode(enable_disable)
    case enable_disable
    when :enable
      custom_iptables_chain('FOREMAN_MAINTAIN',
                            ['-i lo -j ACCEPT',
                             '-p tcp --dport 443 -j REJECT'])
    when :disable
      del_custom_iptables_chain('FOREMAN_MAINTAIN')
    else
      raise "Unexpected argument #{enable_disable}"
    end
  end

  private

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
