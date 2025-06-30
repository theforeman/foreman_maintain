module Procedures::Restore
  class IopRemediationsDump < ForemanMaintain::Procedure
    metadata do
      description 'Restore IoP Remediations dump from backup'
      param :backup_dir,
        'Path to backup directory',
        :required => true
      preparation_steps { Checks::IopRemediations::DBUp.new }
      confine do
        feature(:iop_remediations_database)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)

      with_spinner('Restoring IoP Remediations dump') do |_spinner|
        if backup.file_map[:candlepin_dump][:present]
          local = feature(:iop_remediations_database).local?
          feature(:iop_remediations_database).restore_dump(
            backup.file_map[:iop_remediations_dump][:path], local
          )
        end
      end
    end
  end
end
