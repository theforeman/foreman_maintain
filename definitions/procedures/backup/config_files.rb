module Procedures::Backup
  class ConfigFiles < ForemanMaintain::Procedure
    metadata do
      description 'Backup config files'
      tags :backup
      preparation_steps do
        if feature(:foreman_proxy) && !feature(:foreman_proxy).internal?
          Checks::Backup::CertsTarExist.new
        end
      end
      MAX_RETRIES = 3
      param :backup_dir, 'Directory where to backup to', :required => true
      param :proxy_features, 'List of proxy features to backup (default: all)',
            :array => true, :default => ['all']
      param :ignore_changed_files, 'Should packing tar ignore changed files',
            :flag => true, :default => false
    end

    def run
      with_spinner('Collecting config files to backup') do
        create_tarball
      end
    end

    def create_tarball
      (1..MAX_RETRIES).each do |ret|
        exit_status = execute_tar_cmd
        break unless statuses.include? exit_status

        warn "\nRemoving config files archive #{@tarball_path} as its incomplete"
        execute("rm -rf #{@tarball_path}")
        warn "Recollecting config files backup, retry #{ret} !"
        warn! 'Config files backup failed' if MAX_RETRIES == ret
      end
    end

    def execute_tar_cmd
      @tarball_path ||= File.join(@backup_dir, 'config_files.tar.gz')
      @increments_path ||= File.join(@backup_dir, '.config.snar')
      configs, to_exclude = config_files
      feature(:tar).run(
        :command => 'create', :gzip => true, :archive => @tarball_path,
        :listed_incremental => @increments_path, :ignore_failed_read => true,
        :exclude => to_exclude, :allow_changing_files => @ignore_changed_files,
        :files => configs.join(' ')
      )
    end

    def statuses
      @ignore_changed_files ? [0, 1] : [0]
    end

    # rubocop:disable Metrics/AbcSize
    def config_files
      configs = []
      exclude_configs = []
      ForemanMaintain.available_features.each do |feature|
        # exclude proxy as it has special handling later
        next if [:foreman_proxy, :capsule].include?(feature.label)

        configs += feature.config_files
        exclude_configs += feature.config_files_to_exclude
      end

      if feature(:foreman_proxy)
        configs += feature(:foreman_proxy).config_files(@proxy_features)
        exclude_configs += feature(:foreman_proxy).config_files_to_exclude(@proxy_features)
      end

      configs.compact.select { |path| Dir.glob(path).any? }
      exclude_configs.compact.select { |path| Dir.glob(path).any? }
      [configs, exclude_configs]
    end
    # rubocop:enable Metrics/AbcSize
  end
end
