module Checks
  module IopVmaas
    class DBUp < ForemanMaintain::Check
      metadata do
        description 'Make sure IoP Vmaas DB is up'
        label :iop_vmaas_db_up
        for_feature :iop_vmaas
      end

      def run
        status = false
        if feature(:iop_vmaas_database).psql_cmd_available?
          with_spinner('Checking connection to the IoP Vmaas DB') do
            status = feature(:iop_vmaas_database).ping
          end
          assert(status, 'IoP Vmaas DB is not responding. ' \
            'It needs to be up and running to perform the following steps',
            :next_steps => start_pgsql)
        else
          feature(:iop_vmaas_database).raise_psql_missing_error
        end
      end

      def start_pgsql
        if feature(:iop_vmaas_database).local?
          [Procedures::Service::Start.new(:only => 'postgresql')]
        else
          [] # there is nothing we can do for remote db
        end
      end
    end
  end
end
