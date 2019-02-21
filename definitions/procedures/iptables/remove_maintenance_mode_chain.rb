module Procedures::Iptables
  class RemoveMaintenanceModeChain < ForemanMaintain::Procedure
    metadata do
      label :iptables_remove_maintenance_mode_chain
      for_feature :iptables
      description 'Remove maintenance_mode chain from iptables'
      tags :post_migrations, :maintenance_mode_off
      after :sync_plans_enable
    end

    def run
      feature(:iptables).remove_maintenance_mode_chain
    end
  end
end
