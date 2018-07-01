class Features::Iptables < ForemanMaintain::Feature
  metadata do
    label :iptables
  end

  def perform_action(action_name)
    case action_name
    when 'add_chain'
      custom_iptables_chain(chain_name,
                            ['-i lo -j ACCEPT',
                             '-p tcp --dport 443 -j REJECT'])
    when 'remove_chain'
      del_custom_iptables_chain(chain_name)
    else
      raise "Unexpected argument #{action_name}"
    end
  end

  def chain_name
    'FOREMAN_MAINTAIN'
  end

  def maintenance_mode?
    is_chain_present = custom_chain_exists?(chain_name)
    is_rules_present = chain_rules_exist?(chain_name)
    return 2 if (is_chain_present && !is_rules_present) || (!is_chain_present && is_rules_present)
    return 0 unless is_chain_present
    1
  end

  private

  def custom_iptables_chain(name, rules)
    # if the chain already exists, we assume it was set before: we're not touching
    # it again
    return if custom_chain_exists?(name)
    execute!("iptables -N #{name}")
    rules.each do |rule|
      execute!("iptables -A #{name} #{rule}")
    end
    execute!("iptables -I INPUT -j #{name}")
  end

  def del_custom_iptables_chain(name)
    return unless custom_chain_exists?(name) # the chain is already gone
    execute!("iptables -D INPUT -j #{name}") if chain_rules_exist?(name)
    execute!("iptables -F #{name}")
    execute!("iptables -X #{name}")
  end

  def custom_chain_exists?(name)
    execute?("iptables -L #{name}")
  end

  def chain_rules_exist?(name)
    execute?("iptables -L INPUT | tail -n +3 | grep '^#{name} '")
  end
end
