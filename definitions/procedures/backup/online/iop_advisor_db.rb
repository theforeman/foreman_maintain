module Procedures::Backup
  module Online
    class IopAdvisorDB < ForemanMaintain::Procedure
      metadata do
        description 'Backup IoP Advisor database'
        tags :backup
        label :backup_online_iop_advisor_db
        for_feature :iop_advisor_database
        preparation_steps { Checks::IopAdvisor::DBUp.new }
        param :backup_dir, 'Directory where to backup to', :required => true
      end

      def run
        with_spinner('Getting IoP Advisor DB dump') do
          feature(:iop_advisor_database).dump_db(File.join(@backup_dir, 'iop_advisor.dump'))
        end
      end
    end
  end
end
