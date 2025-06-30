module Procedures::Backup
  module Online
    class IopInventoryDB < ForemanMaintain::Procedure
      metadata do
        description 'Backup IoP Inventory database'
        tags :backup
        label :backup_online_iop_inventory_db
        for_feature :iop_inventory_database
        preparation_steps { Checks::IopInventory::DBUp.new }
        param :backup_dir, 'Directory where to backup to', :required => true
      end

      def run
        with_spinner('Getting IoP Inventory DB dump') do
          feature(:iop_inventory_database).dump_db(File.join(@backup_dir, 'iop_inventory.dump'))
        end
      end
    end
  end
end
