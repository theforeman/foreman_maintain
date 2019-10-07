module Procedures::Backup
  class CompressData < ForemanMaintain::Procedure
    metadata do
      description 'Compress backup data to save space'
      tags :backup
      param :backup_dir, 'Directory where to backup to', :required => true
    end

    def run
      compress_file('pgsql_data.tar', 'Postgres DB')
      compress_file('mongo_data.tar', 'Mongo DB')
    end

    private

    def compress_file(archive, archive_name)
      data_tar = File.join(@backup_dir, archive)
      if File.exist?(data_tar)
        with_spinner("Compressing backup of #{archive_name}") do
          gzip = spawn('gzip', data_tar, '-f')
          Process.wait(gzip)
        end
      end
    end
  end
end
