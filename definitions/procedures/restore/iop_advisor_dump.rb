module Procedures::Restore
  class IopAdvisorDump < ForemanMaintain::Procedure
    metadata do
      description 'Restore IoP Advisor dump from backup'
      param :backup_dir,
        'Path to backup directory',
        :required => true
      preparation_steps { Checks::IopAdvisor::DBUp.new }
      confine do
        feature(:iop_advisor_database)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)

      with_spinner('Restoring IoP Advisor dump') do |_spinner|
        if backup.file_map[:candlepin_dump][:present]
          local = feature(:iop_advisor_database).local?
          feature(:iop_advisor_database).restore_dump(
            backup.file_map[:iop_advisor_dump][:path], local
          )
        end
      end
    end
  end
end
