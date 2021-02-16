module Checks
  module Mongo
    class DBUp < ForemanMaintain::Check
      metadata do
        description 'Make sure Mongo DB is up'
        label :mongo_db_up
        for_feature :mongo
      end

      def run
        status = false
        if feature(:mongo).mongo_cmd_available?
          with_spinner('Checking connection to the Mongo DB') do
            status = feature(:mongo).ping
          end
          assert(status, 'Mongo DB is not responding. ' \
            'It needs to be up and running to perform the following steps.',
                 :next_steps => start_mongodb)
        else
          feature(:mongo).raise_mongo_client_missing_error
        end
      end

      def start_mongodb
        if feature(:mongo).local?
          [Procedures::Service::Start.new(:only => feature(:mongo).services)]
        else
          [] # there is nothing we can do for remote db
        end
      end
    end
  end
end
