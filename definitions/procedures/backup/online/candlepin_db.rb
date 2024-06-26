module Procedures::Backup
  module Online
    class CandlepinDB < ForemanMaintain::Procedure
      metadata do
        description 'Backup Candlepin database'
        tags :backup
        label :backup_online_candlepin_db
        for_feature :candlepin_database
        preparation_steps { Checks::Candlepin::DBUp.new }
        param :backup_dir, 'Directory where to backup to', :required => true
      end

      def run
        with_spinner('Getting Candlepin DB dump') do
          feature(:candlepin_database).dump_db(File.join(@backup_dir, 'candlepin.dump'))
        end
      end
    end
  end
end
