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
        FileUtils.mkdir_p @backup_dir
        FileUtils.chmod_R 0o770, @backup_dir
      end

      if feature(:instance).postgresql_local? && !@preserve_dir
        FileUtils.chown_R(nil, 'postgres', @backup_dir)
      end

      FileUtils.rm(Dir.glob(File.join(@backup_dir, '.*.snar'))) if @preserve_dir
      if @incremental_dir && !(snar_files = Dir.glob(File.join(@incremental_dir, '.*.snar'))).empty?
        FileUtils.cp(snar_files, @backup_dir)
      else
        raise 'No .snar files found in previous backup directory'
      end
    end
  end
end
