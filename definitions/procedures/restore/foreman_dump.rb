module Procedures::Restore
  class ForemanDump < ForemanMaintain::Procedure
    metadata do
      description 'Restore foreman postgresql dump from backup'
      param :backup_dir,
        'Path to backup directory',
        :required => true
      preparation_steps { Checks::Foreman::DBUp.new }
      confine do
        feature(:foreman_database)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)

      with_spinner('Restoring foreman postgresql dump') do |spinner|
        restore_foreman_dump(backup, spinner)
      end
    end

    def restore_foreman_dump(backup, spinner)
      if backup.file_map[:foreman_dump][:present]
        spinner.update('Restoring foreman dump')
        local = feature(:foreman_database).local?
        feature(:foreman_database).restore_dump(backup.file_map[:foreman_dump][:path], local)
      end
    end
  end
end
