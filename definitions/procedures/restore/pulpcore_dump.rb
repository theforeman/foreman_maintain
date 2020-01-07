module Procedures::Restore
  class PulpcoreDump < ForemanMaintain::Procedure
    metadata do
      description 'Restore pulpcore postgresql dump from backup'
      param :backup_dir,
            'Path to backup directory',
            :required => true
      preparation_steps { Checks::Pulpcore::DBUp.new }
      confine do
        feature(:pulpcore_database)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)

      with_spinner('Restoring pulpcore postgresql dump') do |spinner|
        restore_pulpcore_dump(backup, spinner)
      end
    end

    def restore_pulpcore_dump(backup, spinner)
      if backup.file_map[:pulpcore_dump][:present]
        spinner.update('Restoring pulpcore dump')
        local = feature(:pulpcore_database).local?
        feature(:pulpcore_database).restore_dump(backup.file_map[:pulpcore_dump][:path], local)
      end
    end
  end
end
