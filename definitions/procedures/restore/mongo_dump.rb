module Procedures::Restore
  class MongoDump < ForemanMaintain::Procedure
    metadata do
      description 'Restore mongo dump'
      for_feature :pulp
      param :backup_dir,
            'Path to backup directory',
            :required => true
      preparation_steps do
        [Checks::Mongo::DBUp.new, Checks::Mongo::ToolsInstalled.new]
      end
      confine do
        feature(:mongo) && feature(:pulp)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)
      with_spinner('Restoring mongo dump') do |spinner|
        feature(:service).handle_services(spinner, 'start', :only => feature(:mongo).services.keys)
        drop_and_restore_mongo(backup, spinner)
        feature(:service).handle_services(spinner, 'stop', :only => feature(:mongo).services.keys)
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
