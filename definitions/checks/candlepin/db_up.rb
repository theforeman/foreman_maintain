module Checks
  module Candlepin
    class DBUp < ForemanMaintain::Check
      metadata do
        description 'Make sure Candlepin DB is up'
        label :candlepin_db_up
        for_feature :candlepin_database
      end

      def run
        status = false
        if feature(:candlepin_database).psql_cmd_available?
          with_spinner('Checking connection to the Candlepin DB') do
            status = feature(:candlepin_database).ping
          end
          assert(status, 'Candlepin DB is not responding. ' \
            'It needs to be up and running to perform the following steps',
            :next_steps => start_pgsql)
        else
          feature(:candlepin_database).raise_psql_missing_error
        end
      end

      def start_pgsql
        if feature(:candlepin_database).local?
          [Procedures::Service::Start.new(:only => 'postgresql')]
        else
          [] # there is nothing we can do for remote db
        end
      end
    end
  end
end
