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
        with_spinner('Checking connection to the Mongo DB') do
          status = feature(:mongo).ping
        end
        assert(status, 'Mongo DB is not responding. ' \
          'It needs to be up and running to perform the following steps.',
               :next_steps => next_steps)
      end

      def next_steps
        if feature(:mongo).local?
          [Procedures::Service::Start.new(:only => 'mongod')]
        else
          [] # there is nothing we can do for remote db
        end
      end
    end
  end
end
