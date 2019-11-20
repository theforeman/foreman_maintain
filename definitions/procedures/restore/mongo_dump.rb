module Procedures::Restore
  class MongoDump < ForemanMaintain::Procedure
    metadata do
      description 'Restore mongo dump'
      for_feature :pulp2
      param :backup_dir,
            'Path to backup directory',
            :required => true
      preparation_steps do
        [Checks::Mongo::DBUp.new, Checks::Mongo::ToolsInstalled.new]
      end
      confine do
        feature(:mongo) && feature(:pulp2)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)
      with_spinner('Restoring mongo dump') do |spinner|
        handle_mongo_service('start', spinner)
        drop_and_restore_mongo(backup, spinner)
        handle_mongo_service('stop', spinner)
      end
    end

    def handle_mongo_service(action, spinner)
      if feature(:instance).database_local?(:mongo)
        feature(:service).handle_services(spinner, action,
                                          :only => feature(:mongo).services)
      end
    end

    def drop_and_restore_mongo(backup, spinner)
      spinner.update('Dropping pulp_database')
      feature(:mongo).dropdb

      spinner.update('Restoring mongo dump')
      feature(:mongo).restore(backup.file_map[:mongo_dump][:path])
    end
  end
end
