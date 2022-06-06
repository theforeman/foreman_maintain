module Procedures::Backup
  module Offline
    class ForemanDB < ForemanMaintain::Procedure
      metadata do
        description 'Backup Foreman DB offline'
        tags :backup
        label :backup_offline_foreman_db
        for_feature :foreman_database
        preparation_steps { Checks::Foreman::DBUp.new unless feature(:foreman_database).local? }
        param :backup_dir, 'Directory where to backup to', :required => true
        param :tar_volume_size, 'Size of tar volume (indicates splitting)'
        param :mount_dir, 'Snapshot mount directory'
      end

      def run
        if feature(:foreman_database).local?
          if File.exist?(pg_backup_file)
            puts 'Already done'
          else
            local_backup
          end
        else
          puts "Backup of #{pg_data_dir} is not supported for remote databases." \
            ' Doing postgres dump instead...'
          with_spinner('Getting Foreman DB dump') do
            feature(:foreman_database).dump_db(File.join(@backup_dir, 'foreman.dump'))
          end
        end
      end

      private

      def local_backup
        with_spinner("Collecting data from #{pg_data_dir}") do
          if el?
            do_backup
          elsif pg_data_dir.size == 1
            do_backup(pg_data_dir.first)
          else
            deb_local_backup
          end
        end
      end

      def deb_local_backup
        # We take backup of first dir
        first_dir = pg_data_dir.first
        pg_data_dir.delete(first_dir)
        do_backup(first_dir)

        # We append the rest of the dirs to pgsql_data.tar file
        pg_data_dir.each do |pg_dir|
          do_backup(pg_dir, 'append')
        end
      end

      def do_backup(pg_dir = pg_data_dir, cmd = 'create')
        feature(:foreman_database).backup_local(
          pg_backup_file,
          :listed_incremental => File.join(@backup_dir, '.postgres.snar'),
          :volume_size => @tar_volume_size,
          :data_dir => pg_dir,
          :command => cmd
        )
      end

      def pg_backup_file
        File.join(@backup_dir, 'pgsql_data.tar')
      end

      def pg_data_dir
        if el?
          pg_data_dir_el
        else
          pg_data_dirs_deb
        end
      end

      def pg_data_dirs_deb
        # The Debian based OSes support multiple installations of Postgresql
        # There could be situations where Foreman db is either of these versions
        # To be sure we backup the system correctly without missing anything
        # we backup all of the Postgresql dirs
        # Yet to implement the snapshot backup!
        feature(:foreman_database).data_dir
      end

      def pg_data_dir_el
        return feature(:foreman_database).data_dir if @mount_dir.nil?
        mount_point = File.join(@mount_dir, 'pgsql')
        dir = feature(:foreman_database).find_base_directory(mount_point)
        fail!("Snapshot of Foreman DB was not found mounted in #{mount_point}") if dir.nil?
        dir
      end
    end
  end
end
