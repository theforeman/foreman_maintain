module Procedures::Restore
  class PostgresDumps < ForemanMaintain::Procedure
    metadata do
      description 'Restore postgresql dumps from backup'

      param :backup_dir,
            'Path to backup directory',
            :required => true

      confine do
        feature(:foreman_database) || feature(:candlepin_database)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)

      unless backup.file_map[:foreman_dump][:present] || backup.file_map[:candlepin_dump][:present]
        skip 'No postgresql dump files to restore'
      end

      restore_dumps(backup)
    end

    def restore_dumps(backup)
      with_spinner('Restoring any existing postgresql dumps') do |spinner|
        feature(:service).handle_services(spinner, 'start', :only => ['postgresql'])

        restore_foreman_dump(backup, spinner)
        restore_candlepin_dump(backup, spinner)

        feature(:service).handle_services(spinner, 'stop', :only => ['postgresql'])
      end
    end

    def restore_foreman_dump(backup, spinner)
      if backup.file_map[:foreman_dump][:present]
        spinner.update('Restoring foreman dump')
        local = feature(:foreman_database).local?
        feature(:foreman_database).restore_dump(backup.file_map[:foreman_dump][:path], local)
      end
    end

    def restore_candlepin_dump(backup, spinner)
      if backup.file_map[:candlepin_dump][:present]
        spinner.update('Restoring candlepin dump')
        local = feature(:candlepin_database).local?
        feature(:candlepin_database).restore_dump(backup.file_map[:candlepin_dump][:path], local)
      end
    end
  end
end
