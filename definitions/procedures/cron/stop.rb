module Procedures::Cron
  class Stop < ForemanMaintain::Procedure
    metadata do
      description 'Stop cron service'
      tags :pre_migrations
      for_feature :maintenance_mode
      after :iptables_add_chain
      advanced_run false
      confine do
        ForemanMaintain.config.enable_cron_stop
      end
    end

    def run
      feature(:maintenance_mode).perform_action(:cron, 'stop')
    end
  end
end
