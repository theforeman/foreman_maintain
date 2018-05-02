module Procedures::Restore
  class MongoDump < ForemanMaintain::Procedure
    metadata do
      description 'Restore mongo dump'
      for_feature :pulp
      param :backup_dir,
            'Path to backup directory',
            :required => true

      confine do
        feature(:mongo) && feature(:pulp)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)
      if backup.file_map[:mongo_dump][:present]
        with_spinner('Restoring mongo dump') do |spinner|
          feature(:service).handle_services(spinner, 'start', :only => feature(:mongo).services.keys)
          drop_and_restore_mongo(backup, spinner)
          feature(:service).handle_services(spinner, 'stop', :only => feature(:mongo).services.keys)
        end
      else
        skip 'No mongo_dump folder found.'
      end
    end

    def drop_and_restore_mongo(backup, spinner)
      spinner.update('Dropping pulp_database')
      feature(:mongo).dropdb

      spinner.update('Restoring mongo dump')
      feature(:mongo).restore(File.join(backup.file_map[:mongo_dump][:path], 'pulp_database'))
    end
  end
end
