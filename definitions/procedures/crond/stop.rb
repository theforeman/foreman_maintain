require 'procedures/service/base'

module Procedures::Crond
  class Stop < Procedures::Service::Base
    metadata do
      description 'Stop cron service'
      tags :pre_migrations, :maintenance_mode_on
      for_feature :cron

      after :iptables_add_maintenance_mode_chain
      advanced_run false
    end

    def run
      run_service_action('stop', :only => [feature(:cron).service_name])
    end
  end
end
