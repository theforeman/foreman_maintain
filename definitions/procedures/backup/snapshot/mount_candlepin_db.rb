require 'procedures/backup/snapshot/mount_base'
module Procedures::Backup
  module Snapshot
    class MountCandlepinDB < MountBase
      metadata do
        description 'Create and mount snapshot of Candlepin DB'
        tags :backup
        label :backup_snapshot_mount_candlepin_db
        for_feature :candlepin_database
        preparation_steps { Checks::Candlepin::DBUp.new unless feature(:candlepin_database).local? }
        MountBase.common_params(self)
        param :backup_dir, 'Directory where to backup to'
      end

      def run
        if feature(:candlepin_database).local?
          snapshot
        else
          dump_candlepin
        end
      end

      private

      def dump_candlepin
        puts 'LV snapshots are not supported for remote databases. Doing postgres dump instead... '
        with_spinner('Getting Candlepin DB dump') do
          feature(:candlepin_database).dump_db(File.join(@backup_dir, 'candlepin.dump'))
        end
      end

      # rubocop:disable Metrics/MethodLength
      def snapshot
        mount_point = mount_location('pgsql')
        FileUtils.mkdir_p(mount_point) unless File.directory?(mount_point)
        if !mounted?(mount_point)
          if directory_empty?(dir)
            with_spinner('Creating snapshot of Postgres') do |spinner|
              lv_info = get_lv_info(feature(:candlepin_database).data_dir)
              create_lv_snapshot('pgsql-snap', @block_size, lv_info[0])
              spinner.update("Mounting snapshot of Postgres on #{mount_point}")
              mount_snapshot('pgsql', lv_info[1])
            end
          else
            puts "Error: #{mount_point} is not empty."
            exit 1
          end
        else
          puts 'Snapshot of Postgres is already mounted'
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
