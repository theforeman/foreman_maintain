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

        if feature(:instance).postgresql_local?
          FileUtils.chown_R(nil, 'postgres', @backup_dir)
        end
      end

      FileUtils.rm(Dir.glob(File.join(@backup_dir, '.*.snar'))) if @preserve_dir
      if @incremental_dir
        if (snar_files = Dir.glob(File.join(@incremental_dir, '.*.snar'))).empty?
          raise "#{@incremental_dir}/*.snar files unavailable. "\
                'Provide a valid previous backup directory'
        else
          FileUtils.cp(snar_files, @backup_dir)
        end
      end
    end
  end
end
