module Checks
  module IopAdvisor
    class DBUp < ForemanMaintain::Check
      metadata do
        description 'Make sure IoP Advisor DB is up'
        label :iop_advisor_db_up
        for_feature :iop_advisor
      end

      def run
        status = false
        if feature(:iop_advisor_database).psql_cmd_available?
          with_spinner('Checking connection to the IoP Advisor DB') do
            status = feature(:iop_advisor_database).ping
          end
          assert(status, 'IoP Advisor DB is not responding. ' \
            'It needs to be up and running to perform the following steps',
            :next_steps => start_pgsql)
        else
          feature(:iop_advisor_database).raise_psql_missing_error
        end
      end

      def start_pgsql
        if feature(:iop_advisor_database).local?
          [Procedures::Service::Start.new(:only => 'postgresql')]
        else
          [] # there is nothing we can do for remote db
        end
      end
    end
  end
end
