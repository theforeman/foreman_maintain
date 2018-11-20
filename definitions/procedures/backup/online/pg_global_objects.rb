module Procedures::Backup
  module Online
    class PgGlobalObjects < ForemanMaintain::Procedure
      include ForemanMaintain::Concerns::SystemHelpers

      metadata do
        description 'Backup Postgres global objects online'
        tags :backup
        param :backup_dir, 'Directory where to backup to', :required => true
        confine do
          feature(:foreman_database) || feature(:candlepin_database)
        end
      end

      def run
        if feature(:instance).postgresql_local?
          local_db = if feature(:instance).database_local?(:foreman_database)
                       :foreman_database
                     else
                       :candlepin_database
                     end
          feature(local_db).backup_global_objects(File.join(@backup_dir, 'pg_globals.dump'))
        else
          skip 'Backup of global objects is not supported for remote databases.'
        end
      end
    end
  end
end
