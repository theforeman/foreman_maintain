module Procedures::Restore
  class DropDatabases < ForemanMaintain::Procedure
    metadata do
      description 'Drop postgresql databases'

      param :backup_dir,
            'Path to backup directory',
            :required => true

      confine do
        feature(:foreman_database) || feature(:candlepin_database) || feature(:pulpcore_database)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)

      with_spinner('Dropping databases') do |spinner|
        feature(:service).handle_services(spinner, 'start', :only => ['postgresql'])
        drop_foreman(backup, spinner)
        drop_candlepin(backup, spinner)
        if feature(:pulpcore)
          drop_pulpcore(backup, spinner)
        end
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
  end
end
