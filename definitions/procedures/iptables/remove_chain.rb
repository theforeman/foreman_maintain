module Procedures::Iptables
  class RemoveChain < ForemanMaintain::Procedure
    metadata do
      label :iptables_remove_chain
      for_feature :iptables
      description 'Remove chain from iptables'
      tags :post_migrations
      advanced_run false
      after :sync_plans_enable
    end

    def run
      feature(:iptables).perform_action('remove_chain')
    end
  end
end
