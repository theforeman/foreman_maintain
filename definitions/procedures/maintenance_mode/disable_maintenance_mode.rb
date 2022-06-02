module Procedures::MaintenanceMode
  class DisableMaintenanceMode < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::Firewall::MaintenanceMode
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
        notify_and_ask_to_install_firewall_utility
      end
    end
  end
end
