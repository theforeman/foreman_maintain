class Features::Iptables < ForemanMaintain::Feature
  metadata do
    label :iptables
  end

  def add_chain(chain_name, rules, rule_chain = 'INPUT')
    # if the chain already exists, we assume it was set before: we're not touching
    # it again
    return if chain_exist?(chain_name)
    execute!("iptables -N #{chain_name}")
    rules.each do |rule|
      execute!("iptables -A #{chain_name} #{rule}")
    end
    execute!("iptables -I #{rule_chain} -j #{chain_name}")
  end

  def remove_chain(chain_name, rule_chain = 'INPUT')
    return unless chain_exist?(chain_name) # the chain is already gone
    execute!("iptables -D #{rule_chain} -j #{chain_name}") if rule_exist?(chain_name, rule_chain)
    execute!("iptables -F #{chain_name}")
    execute!("iptables -X #{chain_name}")
  end

  def chain_exist?(chain_name)
    execute?("iptables -L #{chain_name}")
  end

  def rule_exist?(target_name, rule_chain = 'INPUT')
    execute?("iptables -L #{rule_chain} | tail -n +3 | grep '^#{target_name} '")
  end

  def add_maintenance_mode_chain
    add_chain(custom_chain_name,
              ['-i lo -j ACCEPT', '-p tcp --dport 443 -j REJECT'])
  end

  def remove_maintenance_mode_chain
    remove_chain(custom_chain_name)
  end

  def maintenance_mode_status?
    chain_exist?(custom_chain_name)
  end

  def status_for_maintenance_mode
    if maintenance_mode_status?
      ['Iptables chain: present', []]
    else
      ['Iptables chain: absent', []]
    end
  end

  private

  def custom_chain_name
    'FOREMAN_MAINTAIN'
  end
end
