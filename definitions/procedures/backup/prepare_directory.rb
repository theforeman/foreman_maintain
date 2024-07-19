module Procedures::Backup
  class PrepareDirectory < ForemanMaintain::Procedure
    metadata do
      description 'Prepare backup Directory'
      tags :backup
      param :backup_dir, 'Directory where to backup to', :required => true
      param :preserve_dir, 'Directory where to backup to', :flag => true
      param :incremental_dir, 'Changes since specified backup only'
    end

    # rubocop:disable Metrics/MethodLength
    def run
      unless @preserve_dir
        puts "Creating backup folder #{@backup_dir}"

        FileUtils.mkdir_p @backup_dir
        FileUtils.chmod_R 0o770, @backup_dir

        if feature(:instance).postgresql_local?
          begin
            FileUtils.chown_R(nil, 'postgres', @backup_dir)
          rescue Errno::EPERM
            warn_msg = <<~MSG
              #{@backup_dir} could not be made readable by the 'postgres' user.
              This won't affect the backup procedure, but you have to ensure that
              the 'postgres' user can read the data during restore.
            MSG
            set_status(:warning, warn_msg)
          end
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
    # rubocop:enable Metrics/MethodLength
  end
end
