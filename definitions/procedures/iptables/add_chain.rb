module Procedures::Iptables
  class AddChain < ForemanMaintain::Procedure
    metadata do
      label :iptables_add_chain
      for_feature :iptables
      description 'Add chain to iptables'
      tags :pre_migrations
      advanced_run false
      after :sync_plans_disable
    end

    def run
      feature(:iptables).perform_action('add_chain')
    end
  end
end
