require 'procedures/backup/snapshot/mount_base'
module Procedures::Backup
  module Snapshot
    class MountForemanDB < MountBase
      metadata do
        description 'Create and mount snapshot of Foreman DB'
        tags :backup
        label :backup_snapshot_mount_foreman_db
        for_feature :foreman_database
        preparation_steps { Checks::Foreman::DBUp.new unless feature(:foreman_database).local? }
        MountBase.common_params(self)
        param :backup_dir, 'Directory where to backup to'
      end

      def run
        if feature(:foreman_database).local?
          snapshot
        else
          dump_foreman
        end
      end

      private

      def dump_foreman
        puts 'LV snapshots are not supported for remote databases. Doing postgres dump instead... '
        with_spinner('Getting Foreman DB dump') do
          feature(:foreman_database).dump_db(File.join(@backup_dir, 'foreman.dump'))
        end
      end

      def snapshot
        mount_point = mount_location('pgsql')
        FileUtils.mkdir_p(mount_point) unless File.directory?(mount_point)
        if directory_empty?(mount_point)
          with_spinner('Creating snapshot of Postgres') do |spinner|
            lv_info = get_lv_info(feature(:foreman_database).data_dir)
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
