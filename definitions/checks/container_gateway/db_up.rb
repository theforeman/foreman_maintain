require_relative '../db_up_check'

module Checks
  module ContainerGateway
    class DBUp < DBUpCheck
      metadata do
        description 'Make sure ContainerGateway DB is up'
        label :container_gateway_db_up
        for_feature :container_gateway_database
      end

      def database_feature
        :container_gateway_database
      end

      def database_name
        'Container Gateway'
      end
    end
  end
end
