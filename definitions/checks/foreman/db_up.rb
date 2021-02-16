module Checks
  module Foreman
    class DBUp < ForemanMaintain::Check
      metadata do
        description 'Make sure Foreman DB is up'
        label :foreman_db_up
        for_feature :foreman_database
      end

      def run
        status = false
        if feature(:foreman_database).psql_cmd_available?
          with_spinner('Checking connection to the Foreman DB') do
            status = feature(:foreman_database).ping
          end
          assert(status, 'Foreman DB is not responding. ' \
            'It needs to be up and running to perform the following steps',
                 :next_steps => start_pgsql)
        else
          feature(:foreman_database).raise_psql_missing_error
        end
      end

      def start_pgsql
        if feature(:foreman_database).local?
          [Procedures::Service::Start.new(:only => 'postgresql')]
        else
          [] # there is nothing we can do for remote db
        end
      end
    end
  end
end
