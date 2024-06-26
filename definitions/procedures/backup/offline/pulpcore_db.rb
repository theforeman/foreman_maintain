module Procedures::Backup
  module Offline
    class PulpcoreDB < ForemanMaintain::Procedure
      metadata do
        description 'Backup Pulpcore DB offline'
        tags :backup
        label :backup_offline_pulpcore_db
        for_feature :pulpcore_database
        preparation_steps { Checks::Pulpcore::DBUp.new }
        param :backup_dir, 'Directory where to backup to', :required => true
      end

      def run
        with_spinner('Getting Pulpcore DB dump') do
          feature(:pulpcore_database).dump_db(File.join(@backup_dir, 'pulpcore.dump'))
        end
      end
    end
  end
end
