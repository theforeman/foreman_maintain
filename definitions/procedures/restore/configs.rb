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
        reset_qpid_jrnls
        reload_configs
      end
    end

    # rubocop:disable  Metrics/MethodLength
    def restore_configs(backup)
      exclude = ForemanMaintain.available_features.each_with_object([]) do |feat, cfgs|
        if backup.online_backup?
          feat.config_files_exclude_for_online.each { |f| cfgs << f.gsub(%r{^/}, '') }
        end
        feat.config_files_to_exclude.each { |f| cfgs << f.gsub(%r{^/}, '') }
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
    # rubocop:enable  Metrics/MethodLength

    def reload_configs
      feature(:mongo).reload_db_config if feature(:mongo)
    end

    private

    def clean_conflicting_data
      # tar is unable to --overwrite dir with symlink
      execute('rm -rf /usr/share/foreman-proxy/.ssh')
    end

    def reset_qpid_jrnls
      # on restore without pulp data qpid fails to start
      # https://access.redhat.com/solutions/4645231
      execute('rm -rf /var/lib/qpidd/.qpidd/qls/dat2/__db.00*')
    end
  end
end
