require 'procedures/backup/snapshot/mount_base'
module Procedures::Backup
  module Snapshot
    class MountPulpcoreDB < MountBase
      metadata do
        description 'Create and mount snapshot of Pulpcore DB'
        tags :backup
        label :backup_snapshot_mount_pulpcore_db
        for_feature :pulpcore_database
        preparation_steps { Checks::Pulpcore::DBUp.new unless feature(:pulpcore_database).local? }
        MountBase.common_params(self)
        param :backup_dir, 'Directory where to backup to'
      end

      def run
        if feature(:pulpcore_database).local?
          snapshot
        else
          dump_pulpcore
        end
      end

      private

      def dump_pulpcore
        puts 'LV snapshots are not supported for remote databases. Doing postgres dump instead... '
        with_spinner('Getting Pulpcore DB dump') do
          feature(:pulpcore_database).dump_db(File.join(@backup_dir, 'pulpcore.dump'))
        end
      end

      def snapshot
        mount_point = mount_location('pgsql')
        FileUtils.mkdir_p(mount_point) unless File.directory?(mount_point)
        if directory_empty?(mount_point)
          with_spinner('Creating snapshot of Postgres') do |spinner|
            lv_info = get_lv_info(feature(:pulpcore_database).data_dir)
            create_lv_snapshot('pgsql-snap', @block_size, lv_info[0])
            spinner.update("Mounting snapshot of Postgres on #{mount_point}")
            mount_snapshot('pgsql', lv_info[1])
          end
        else
          puts 'Snapshot of Postgres is already mounted'
        end
      end
    end
  end
end
