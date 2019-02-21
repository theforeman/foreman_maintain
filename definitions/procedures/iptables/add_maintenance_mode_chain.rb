module Procedures::Iptables
  class AddMaintenanceModeChain < ForemanMaintain::Procedure
    metadata do
      label :iptables_add_maintenance_mode_chain
      for_feature :iptables
      description 'Add maintenance_mode chain to iptables'
      tags :pre_migrations, :maintenance_mode_on
      after :sync_plans_disable
    end

    def run
      feature(:iptables).add_maintenance_mode_chain
    end
  end
end
