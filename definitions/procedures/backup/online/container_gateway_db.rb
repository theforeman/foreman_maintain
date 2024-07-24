module Procedures::Backup
  module Online
    class ContainerGatewayDB < ForemanMaintain::Procedure
      metadata do
        description 'Backup Container Gateway database'
        tags :backup
        label :backup_online_container_gateway_db
        for_feature :container_gateway_database
        preparation_steps { Checks::ContainerGateway::DBUp.new }
        param :backup_dir, 'Directory where to backup to', :required => true
      end

      def run
        with_spinner('Getting Container Gateway DB dump') do
          feature(:container_gateway_database).
            dump_db(File.join(@backup_dir, 'container_gateway.dump'))
        end
      end
    end
  end
end
