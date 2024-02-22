module Procedures::Backup
  module Offline
    class CandlepinDB < ForemanMaintain::Procedure
      metadata do
        description 'Backup Candlepin DB offline'
        tags :backup
        label :backup_offline_candlepin_db
        for_feature :candlepin_database
        preparation_steps { Checks::Candlepin::DBUp.new unless feature(:candlepin_database).local? }
        param :backup_dir, 'Directory where to backup to', :required => true
        param :tar_volume_size, 'Size of tar volume (indicates splitting)'
      end

      def run
        if feature(:candlepin_database).local?
          if File.exist?(pg_backup_file)
            puts 'Already done'
          else
            local_backup
          end
        else
          puts "Backup of #{pg_data_dir} is not supported for remote databases." \
            ' Doing postgres dump instead...'
          with_spinner('Getting Candlepin DB dump') do
            feature(:candlepin_database).dump_db(File.join(@backup_dir, 'candlepin.dump'))
          end
        end
      end

      private

      def local_backup
        with_spinner("Collecting data from #{pg_data_dir}") do
          feature(:candlepin_database).backup_local(
            pg_backup_file,
            :listed_incremental => File.join(@backup_dir, '.postgres.snar'),
            :volume_size => @tar_volume_size,
            :data_dir => pg_data_dir,
            :restore_dir => feature(:candlepin_database).data_dir
          )
        end
      end

      def pg_backup_file
        File.join(@backup_dir, 'pgsql_data.tar')
      end

      def pg_data_dir
        feature(:candlepin_database).data_dir
      end
    end
  end
end
