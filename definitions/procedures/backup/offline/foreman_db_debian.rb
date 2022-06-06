module Procedures::Backup
  module Offline
    class ForemanDBDebian < ForemanMaintain::Procedure
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
          feature(:foreman_database).backup_local(
            pg_backup_file,
            :listed_incremental => File.join(@backup_dir, '.postgres.snar'),
            :volume_size => @tar_volume_size,
            :data_dir => pg_data_dir
          )
        end
      end

      def pg_backup_file
        File.join(@backup_dir, 'pgsql_data.tar')
      end

      def pg_data_dir
        return feature(:foreman_database).data_dir if @mount_dir.nil?
        mount_point = File.join(@mount_dir, 'pgsql')
        dir = feature(:foreman_database).find_base_directory(mount_point)
        fail!("Snapshot of Foreman DB was not found mounted in #{mount_point}") if dir.nil?
        dir
      end
    end
  end
end
