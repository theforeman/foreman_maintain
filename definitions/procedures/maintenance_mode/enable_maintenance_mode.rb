module Procedures::MaintenanceMode
  class EnableMaintenanceMode < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::Firewall::MaintenanceMode
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
        notify_and_ask_to_install_firewall_utility
      end
    end
  end
end
