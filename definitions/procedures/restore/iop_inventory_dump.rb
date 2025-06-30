module Procedures::Restore
  class IopInventoryDump < ForemanMaintain::Procedure
    metadata do
      description 'Restore IoP Inventory dump from backup'
      param :backup_dir,
        'Path to backup directory',
        :required => true
      preparation_steps { Checks::IopInventory::DBUp.new }
      confine do
        feature(:iop_inventory_database)
      end
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)

      with_spinner('Restoring IoP Inventory dump') do |_spinner|
        if backup.file_map[:candlepin_dump][:present]
          local = feature(:iop_inventory_database).local?
          feature(:iop_inventory_database).restore_dump(
            backup.file_map[:iop_inventory_dump][:path], local
          )
        end
      end
    end
  end
end
