module Procedures::MaintenanceMode
  class EnableMaintenanceMode < ForemanMaintain::Procedure
    metadata do
      label :enable_maintenance_mode
      description 'Add maintenance_mode tables/chain to nftables/iptables'
      tags :pre_migrations, :maintenance_mode_on
      after :sync_plans_disable
    end

    def run
      if feature(:instance).firewall
        feature(:instance).firewall.enable_maintenance_mode
      else
        warn! 'Unable to find iptables or nftables!'
      end
    end
  end
end
