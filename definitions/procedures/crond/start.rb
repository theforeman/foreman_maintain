require 'procedures/service/base'

module Procedures::Crond
  class Start < Procedures::Service::Base
    metadata do
      description 'Start cron service'

      for_feature :cron
      tags :post_migrations, :maintenance_mode_off

      after :iptables_remove_maintenance_mode_chain
      advanced_run false
    end

    def run
      run_service_action('start', :only => [feature(:cron).service_name])
    end
  end
end
