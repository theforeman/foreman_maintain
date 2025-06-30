module Procedures::Restore
  class IopVmaasDump < ForemanMaintain::Procedure
    metadata do
      description 'Restore IoP Vmaas dump from backup'
      param :backup_dir,
        'Path to backup directory',
        :required => true
      preparation_steps { Checks::IopVmaas::DBUp.new }
      confine do
        feature(:iop_vmaas_database)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)

      with_spinner('Restoring IoP Vmaas dump') do |_spinner|
        if backup.file_map[:candlepin_dump][:present]
          local = feature(:iop_vmaas_database).local?
          feature(:iop_vmaas_database).restore_dump(backup.file_map[:iop_vmaas_dump][:path], local)
        end
      end
    end
  end
end
