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
        clean_conflicting_data
        restore_configs(backup)
        reload_configs
      end
    end

    def restore_configs(backup)
      exclude = ForemanMaintain.available_features.each_with_object([]) do |feat, cfgs|
        feat.config_files_to_exclude.each { |f| cfgs << f }
      end
      tar_options = {
        :overwrite => true,
        :listed_incremental => '/dev/null',
        :command => 'extract',
        :directory => '/',
        :archive => backup.file_map[:config_files][:path],
        :gzip => true,
        :exclude => exclude
      }

      feature(:tar).run(tar_options)
    end

    def reload_configs
      feature(:mongo).reload_db_config if feature(:mongo)
    end

    private

    def clean_conflicting_data
      # tar is unable to --overwrite dir with symlink
      execute('rm -rf /usr/share/foreman-proxy/.ssh')
    end
  end
end
