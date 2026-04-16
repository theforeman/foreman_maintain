module Procedures::Restore
  class DropDatabases < ForemanMaintain::Procedure
    metadata do
      description 'Drop postgresql databases'

      param :backup_dir,
        'Path to backup directory',
        :required => true

      confine do
        feature(:foreman_database) || feature(:candlepin_database) || feature(:pulpcore_database) ||
          feature(:iop_advisor_database) ||
          feature(:iop_inventory_database) ||
          feature(:iop_remediations_database) ||
          feature(:iop_vmaas_database) ||
          feature(:iop_vulnerability_database) ||
          feature(:container_gateway_database)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)

      with_spinner('Dropping databases') do |spinner|
        feature(:service).handle_services(spinner, 'start', :only => ['postgresql'])
        drop_foreman(backup, spinner)
        drop_candlepin(backup, spinner)
        drop_pulpcore(backup, spinner)
        drop_iop_advisor(backup, spinner)
        drop_iop_inventory(backup, spinner)
        drop_iop_remediations(backup, spinner)
        drop_iop_vmaas(backup, spinner)
        drop_iop_vulnerability(backup, spinner)
        drop_container_gateway(backup, spinner)
      end
    end

    def drop_foreman(backup, spinner)
      if backup.file_map[:foreman_dump][:present]
        spinner.update('Dropping foreman database')
        feature(:foreman_database).dropdb
      end
    end

    def drop_candlepin(backup, spinner)
      if backup.file_map[:candlepin_dump][:present]
        spinner.update('Dropping candlepin database')
        feature(:candlepin_database).dropdb
      end
    end

    def drop_pulpcore(backup, spinner)
      if backup.file_map[:pulpcore_dump][:present]
        spinner.update('Dropping pulpcore database')
        feature(:pulpcore_database).dropdb
      end
    end

    def drop_iop_advisor(backup, spinner)
      if backup.file_map[:iop_advisor_dump][:present]
        spinner.update('Dropping iop_advisor database')
        feature(:iop_advisor_database).dropdb
      end
    end

    def drop_iop_inventory(backup, spinner)
      if backup.file_map[:iop_inventory_dump][:present]
        spinner.update('Dropping iop_inventory database')
        feature(:iop_inventory_database).dropdb
      end
    end

    def drop_iop_remediations(backup, spinner)
      if backup.file_map[:iop_remediations_dump][:present]
        spinner.update('Dropping iop_remediations database')
        feature(:iop_remediations_database).dropdb
      end
    end

    def drop_iop_vmaas(backup, spinner)
      if backup.file_map[:iop_vmaas_dump][:present]
        spinner.update('Dropping iop_vmaas database')
        feature(:iop_vmaas_database).dropdb
      end
    end

    def drop_iop_vulnerability(backup, spinner)
      if backup.file_map[:iop_vulnerability_dump][:present]
        spinner.update('Dropping iop_vulnerability database')
        feature(:iop_vulnerability_database).dropdb
      end
    end

    def drop_container_gateway(backup, spinner)
      if backup.file_map[:container_gateway_dump][:present]
        spinner.update('Dropping container gateway database')
        feature(:container_gateway_database).dropdb
      end
    end
  end
end
