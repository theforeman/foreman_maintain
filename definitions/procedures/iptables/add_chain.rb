module Procedures::Iptables
  class AddChain < ForemanMaintain::Procedure
    metadata do
      label :iptables_add_chain
      for_feature :maintenance_mode
      description 'Add chain to iptables'
      tags :pre_migrations
      advanced_run false
      after :sync_plans_disable
    end

    def run
      feature(:maintenance_mode).perform_action(:iptables, 'add_chain')
    end
  end
end
