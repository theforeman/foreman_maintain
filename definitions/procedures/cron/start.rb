module Procedures::Cron
  class Start < ForemanMaintain::Procedure
    metadata do
      description 'Start cron service'
      for_feature :maintenance_mode
      tags :post_migrations
      after :iptables_remove_chain
      advanced_run false
      confine do
        ForemanMaintain.config.enable_cron_stop
      end
    end

    def run
      feature(:maintenance_mode).perform_action(:cron, 'start')
    end
  end
end
