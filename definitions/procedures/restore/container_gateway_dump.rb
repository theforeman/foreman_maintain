module Procedures::Restore
  class ContainerGatewayDump < ForemanMaintain::Procedure
    metadata do
      description 'Restore container gateway postgresql dump from backup'
      param :backup_dir,
        'Path to backup directory',
        :required => true
      preparation_steps { Checks::ContainerGateway::DBUp.new }
      confine do
        feature(:container_gateway_database)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)

      with_spinner('Restoring container gateway postgresql dump') do |spinner|
        restore_container_gateway_dump(backup, spinner)
      end
    end

    def restore_container_gateway_dump(backup, spinner)
      if backup.file_map[:container_gateway_dump][:present]
        spinner.update('Restoring container gateway dump')
        local = feature(:container_gateway_database).local?
        feature(:container_gateway_database).
          restore_dump(backup.file_map[:container_gateway_dump][:path], local)
      end
    end
  end
end
