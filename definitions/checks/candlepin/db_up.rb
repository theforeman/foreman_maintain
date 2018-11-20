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
        with_spinner('Checking connection to the Candlepin DB') do
          status = feature(:candlepin_database).ping
        end
        assert(status, 'Candlepin DB is not responding. ' \
          'It needs to be up and running to perform the following steps',
               :next_steps => next_steps)
      end

      def next_steps
        if feature(:candlepin_database).local?
          [Procedures::Service::Start.new(:only => 'postgresql')]
        else
          [] # there is nothing we can do for remote db
        end
      end
    end
  end
end
