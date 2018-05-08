module Procedures::Restore
  class CandlepinDump < ForemanMaintain::Procedure
    metadata do
      description 'Restore candlepin postgresql dump from backup'
      param :backup_dir,
            'Path to backup directory',
            :required => true
      preparation_steps { Checks::Candlepin::DBUp.new unless feature(:candlepin_database).local? }
      confine do
        feature(:candlepin_database)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)

      with_spinner('Restoring candlepin postgresql dump') do |spinner|
        feature(:service).handle_services(spinner, 'start', :only => ['postgresql'])
        restore_candlepin_dump(backup, spinner)
        feature(:service).handle_services(spinner, 'stop', :only => ['postgresql'])
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
