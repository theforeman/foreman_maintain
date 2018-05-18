module Procedures::Restore
  class Configs < ForemanMaintain::Procedure
    metadata do
      description 'Restore configs from backup'

      param :backup_dir,
            'Path to backup directory',
            :required => true
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)
      with_spinner('Resetting') do |spinner|
        spinner.update('Restoring configs')
        restore_configs(backup)
      end
    end

    def restore_configs(backup)
      tar_options = {
        :overwrite => true,
        :listed_incremental => '/dev/null',
        :command => 'extract',
        :directory => '/',
        :archive => backup.file_map[:config_files][:path],
        :gzip => true
      }

      feature(:tar).run(tar_options)
    end
  end
end
