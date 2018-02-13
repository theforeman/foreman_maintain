module Procedures::Backup
  class PrepareDirectory < ForemanMaintain::Procedure
    metadata do
      description 'Prepare backup Directory'
      tags :backup
      param :backup_dir, 'Directory where to backup to', :required => true
      param :preserve_dir, 'Directory where to backup to', :flag => true
      param :incremental_dir, 'Changes since specified backup only'
    end

    def run
      puts "Creating backup folder #{@backup_dir}"

      unless @preserve_dir
        FileUtils.mkdir @backup_dir
        FileUtils.chmod_R 0o770, @backup_dir
      end

      if local_psql_database? && !@preserve_dir
        FileUtils.chown_R(nil, 'postgres', @backup_dir)
      end

      FileUtils.rm(Dir.glob(File.join(@backup_dir, '.*.snar'))) if @preserve_dir
      if @incremental_dir
        FileUtils.cp(Dir.glob(File.join(@incremental_dir, '.*.snar')), @backup_dir)
      end
    end
  end
end
