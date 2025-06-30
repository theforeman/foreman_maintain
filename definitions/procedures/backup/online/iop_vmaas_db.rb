module Procedures::Backup
  module Online
    class IopVmaasDB < ForemanMaintain::Procedure
      metadata do
        description 'Backup IoP Vmaas database'
        tags :backup
        label :backup_online_iop_vmaas_db
        for_feature :iop_vmaas_database
        preparation_steps { Checks::IopVmaas::DBUp.new }
        param :backup_dir, 'Directory where to backup to', :required => true
      end

      def run
        with_spinner('Getting IoP Vmaas DB dump') do
          feature(:iop_vmaas_database).dump_db(File.join(@backup_dir, 'iop_vmaas.dump'))
        end
      end
    end
  end
end
