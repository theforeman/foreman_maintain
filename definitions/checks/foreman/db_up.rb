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
        with_spinner('Checking connection to the Foreman DB') do
          status = feature(:foreman_database).ping
        end
        assert(status, 'Foreman DB is not responding. ' \
          'It needs to be up and running to perform the following steps',
               :next_steps => next_steps)
      end

      def next_steps
        if feature(:foreman_database).local?
          [Procedures::Service::Start.new(:only => 'postgresql')]
        else
          [] # there is nothing we can do for remote db
        end
      end
    end
  end
end
