require 'procedures/backup/snapshot/mount_base'
module Procedures::Backup
  module Snapshot
    class MountMongo < MountBase
      metadata do
        description 'Create and mount snapshot of Mongo DB'
        tags :backup
        for_feature :mongo
        preparation_steps do
          unless feature(:mongo).local?
            [Checks::Mongo::DBUp.new, Checks::Mongo::ToolsInstalled.new]
          end
        end
        MountBase.common_params(self)
        param :backup_dir, 'Directory where to backup to'
      end

      def run
        if feature(:mongo).local?
          mount_local
        else
          puts 'LV snapshots are not supported for remote databases. Doing dump instead...'
          with_spinner('Getting dump of Mongo DB') do
            feature(:mongo).dump(File.join(@backup_dir, 'mongo_dump'))
          end
        end
      end

      private

      def mount_local
        with_spinner('Creating snapshot of Mongo DB') do |spinner|
          feature(:mongo).with_marked_directory(feature(:mongo).data_dir) do
            lv_info = get_lv_info(feature(:mongo).data_dir)
            create_lv_snapshot('mongodb-snap', @block_size, lv_info[0])
            spinner.update("Mounting snapshot of Mongo DB on #{mount_location('mongodb')}")
            mount_snapshot('mongodb', lv_info[1])
          end
        end
      end
    end
  end
end
