module Procedures::Backup
  module Online
    class Mongo < ForemanMaintain::Procedure
      metadata do
        description 'Backup Mongo online'
        tags :backup
        for_feature :mongo
        preparation_steps { Checks::Mongo::DBUp.new }
        param :backup_dir, 'Directory where to backup to', :required => true
      end

      def run
        with_spinner('Getting dump of Mongo DB') do
          feature(:mongo).dump(File.join(@backup_dir, 'mongo_dump'))
        end
      end
    end
  end
end
