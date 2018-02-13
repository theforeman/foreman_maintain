module Procedures::Backup
  module Offline
    class Mongo < ForemanMaintain::Procedure
      metadata do
        description 'Backup mongo offline'
        tags :backup
        for_feature :mongo
        preparation_steps { Checks::Mongo::DBUp.new unless feature(:mongo).local? }
        param :backup_dir, 'Directory where to backup to', :required => true
        param :tar_volume_size, 'Size of tar volume (indicates splitting)'
        param :mount_dir, 'Snapshot mount directory'
      end

      def run
        if feature(:mongo).local?
          local_backup
        else
          dump_mongo
        end
      end

      def data_dir
        return nil if @mount_dir.nil?
        mount_point = File.join(@mount_dir, 'mongodb')
        dir = feature(:mongo).find_base_directory(mount_point)
        fail!("Snapshot of Mongo DB was not found mounted in #{mount_point}") if dir.nil?
        dir
      end

      private

      def dump_mongo
        puts "Backup of #{feature(:mongo).data_dir} is not supported for remote databases." \
            ' Doing dump instead... '
        with_spinner('Getting dump of Mongo DB') do
          feature(:mongo).dump(File.join(@backup_dir, 'mongo_dump'))
        end
      end

      def local_backup
        with_spinner('Collecting Mongo data') do
          feature(:mongo).backup_local(
            File.join(@backup_dir, 'mongo_data.tar'),
            :listed_incremental => File.join(@backup_dir, '.mongo.snar'),
            :volume_size => @tar_volume_size,
            :data_dir => data_dir
          )
        end
      end
    end
  end
end
