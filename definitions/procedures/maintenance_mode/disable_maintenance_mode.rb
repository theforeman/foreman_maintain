module Procedures::MaintenanceMode
  class DisableMaintenanceMode < ForemanMaintain::Procedure
    metadata do
      label :disable_maintenance_mode
      description 'Remove maintenance mode table/chain from nftables/iptables'
      tags :post_migrations, :maintenance_mode_off
      after :sync_plans_enable
    end

    def run
      if feature(:instance).firewall
        feature(:instance).firewall.disable_maintenance_mode
      else
        warn! 'Unable to find nftables or iptables'
      end
    end
  end
end
