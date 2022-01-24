module Procedures::MaintenanceMode
  class DisableMaintenanceMode < ForemanMaintain::Procedure
    metadata do
      label :disable_maintenance_mode
      description 'Remove maintenance mode table/chain from nftables/iptables'
      tags :post_migrations, :maintenance_mode_off
      after :sync_plans_enable
      confine do
        feature(:nftables) || feature(:iptables)
      end
    end

    def run
      if feature(:nftables)
        delete_table_using_nftables
      elsif feature(:iptables)
        feature(:iptables).remove_maintenance_mode_chain
      else
        warn! 'Unable to find nftables or iptables'
      end
    end

    def delete_table_using_nftables
      if feature(:nftables).table_exist?
        feature(:nftables).delete_table
      end
    end
  end
end
