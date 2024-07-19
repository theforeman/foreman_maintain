module Checks
  module ContainerGateway
    class DBUp < ForemanMaintain::Check
      metadata do
        description 'Make sure ContainerGateway DB is up'
        label :container_gateway_db_up
        for_feature :container_gateway_database
      end

      def run
        status = false
        with_spinner('Checking connection to the Container Gateway DB') do
          status = feature(:container_gateway_database).ping
        end
        assert(status, 'Container Gateway DB is not responding. ' \
          'It needs to be up and running to perform the following steps',
          :next_steps => next_steps)
      end

      def next_steps
        if feature(:container_gateway_database).local?
          [Procedures::Service::Start.new(:only => 'postgresql')]
        else
          [] # there is nothing we can do for remote db
        end
      end
    end
  end
end
