module Procedures::Backup
  module Offline
    class ForemanDB < ForemanMaintain::Procedure
      metadata do
        description 'Backup Foreman DB offline'
        tags :backup
        label :backup_offline_foreman_db
        for_feature :foreman_database
        preparation_steps { Checks::Foreman::DBUp.new }
        param :backup_dir, 'Directory where to backup to', :required => true
      end

      def run
        with_spinner('Getting Foreman DB dump') do
          feature(:foreman_database).dump_db(File.join(@backup_dir, 'foreman.dump'))
        end
      end
    end
  end
end
