module Procedures::Backup
  module Online
    class IopRemediationsDB < ForemanMaintain::Procedure
      metadata do
        description 'Backup IoP Remediations database'
        tags :backup
        label :backup_online_iop_remediations_db
        for_feature :iop_remediations_database
        preparation_steps { Checks::IopRemediations::DBUp.new }
        param :backup_dir, 'Directory where to backup to', :required => true
      end

      def run
        with_spinner('Getting IoP Remediations DB dump') do
          feature(:iop_remediations_database).dump_db(File.join(@backup_dir,
            'iop_remediations.dump'))
        end
      end
    end
  end
end
