module Checks
  module IopRemediations
    class DBUp < ForemanMaintain::Check
      metadata do
        description 'Make sure IoP Remediations DB is up'
        label :iop_remediations_db_up
        for_feature :iop_remediations
      end

      def run
        status = false
        if feature(:iop_remediations_database).psql_cmd_available?
          with_spinner('Checking connection to the IoP Remediations DB') do
            status = feature(:iop_remediations_database).ping
          end
          assert(status, 'IoP Remediations DB is not responding. ' \
            'It needs to be up and running to perform the following steps',
            :next_steps => start_pgsql)
        else
          feature(:iop_remediations_database).raise_psql_missing_error
        end
      end

      def start_pgsql
        if feature(:iop_remediations_database).local?
          [Procedures::Service::Start.new(:only => 'postgresql')]
        else
          [] # there is nothing we can do for remote db
        end
      end
    end
  end
end
