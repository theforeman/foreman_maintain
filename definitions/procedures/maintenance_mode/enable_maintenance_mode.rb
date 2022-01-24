module Procedures::MaintenanceMode
  class EnableMaintenanceMode < ForemanMaintain::Procedure
    metadata do
      label :enable_maintenance_mode
      description 'Add maintenance_mode tables/chain to nftables/iptables'
      tags :pre_migrations, :maintenance_mode_on
      after :sync_plans_disable
      confine do
        feature(:nftables) || feature(:iptables)
      end
    end

    def run
      if feature(:nftables)
        nftables_enable_maintenance_mode
      elsif feature(:iptables)
        feature(:iptables).add_maintenance_mode_chain
      else
        warn! 'Unable to find iptables or nftables!'
      end
    end

    def nftables_enable_maintenance_mode
      unless feature(:nftables).table_exist?
        feature(:nftables).add_table
        feature(:nftables).add_chain(:chain_options => nftables_chain_options)
        feature(:nftables).add_rule(rule: nftables_rule)
      end
    end

    def nftables_rule
      'tcp dport https reject'
    end

    def nftables_chain_options
      '{type filter hook input priority 0\\;}'
    end
  end
end
