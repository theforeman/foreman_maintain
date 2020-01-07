module Checks
  module Pulpcore
    class DBUp < ForemanMaintain::Check
      metadata do
        description 'Make sure Pulpcore DB is up'
        label :pulpcore_db_up
        for_feature :pulpcore_database
      end

      def run
        status = false
        with_spinner('Checking connection to the Pulpcore DB') do
          status = feature(:pulpcore_database).ping
        end
        assert(status, 'Pulpcore DB is not responding. ' \
          'It needs to be up and running to perform the following steps',
               :next_steps => next_steps)
      end

      def next_steps
        if feature(:pulpcore_database).local?
          [Procedures::Service::Start.new(:only => 'postgresql')]
        else
          [] # there is nothing we can do for remote db
        end
      end
    end
  end
end
