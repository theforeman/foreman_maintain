module Procedures::Restore
  class PgGlobalObjects < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::SystemHelpers

    metadata do
      description 'Restore any existing postgresql global objects from backup'

      param :backup_dir,
            'Path to backup directory',
            :required => true

      confine do
        feature(:foreman_database) || feature(:candlepin_database)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)

      if backup.file_map[:pg_globals][:present]
        restore_global_objects(backup.file_map[:pg_globals][:path])
      else
        skip 'No postgresql global objects file to restore'
      end
    end

    def restore_global_objects(pg_global_file)
      if feature(:instance).postgresql_local?
        with_spinner('') do |spinner|
          feature(:service).handle_services(spinner, 'start', :only => ['postgresql'])

          spinner.update('Restoring postgresql global objects')
          local_db = feature(:foreman_database).local? ? :foreman_database : :candlepin_database
          feature(local_db).restore_pg_globals(pg_global_file)
        end
      else
        skip 'Restore of global objects is not supported for remote databases.'
      end
    end
  end
end
