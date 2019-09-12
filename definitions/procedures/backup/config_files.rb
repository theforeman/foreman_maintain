module Procedures::Backup
  class ConfigFiles < ForemanMaintain::Procedure
    metadata do
      description 'Backup config files'
      tags :backup
      preparation_steps do
        if feature(:instance).proxy_feature && !feature(:instance).proxy_feature.internal?
          Checks::Backup::CertsTarExist.new
        end
      end
      param :backup_dir, 'Directory where to backup to', :required => true
      param :proxy_features, 'List of proxy features to backup (default: all)',
            :array => true, :default => ['all']
      param :ignore_changed_files, 'Should packing tar ignore changed files',
            :flag => true, :default => false
    end

    def run
      tarball = File.join(@backup_dir, 'config_files.tar.gz')
      increments = File.join(@backup_dir, '.config.snar')
      with_spinner('Collecting config files to backup') do
        configs, to_exclude = config_files
        feature(:tar).run(
          :command => 'create', :gzip => true, :archive => tarball,
          :listed_incremental => increments, :ignore_failed_read => true,
          :exclude => to_exclude, :allow_changing_files => @ignore_changed_files,
          :files => configs.join(' ')
        )
      end
    end

    # rubocop:disable Metrics/AbcSize
    def config_files
      configs = []
      exclude_configs = []
      ForemanMaintain.available_features.each do |feature|
        # exclude proxy as it has special handling later
        next if feature == feature(:instance).proxy_feature

        configs += feature.config_files
        exclude_configs += feature.config_files_to_exclude
      end

      if feature(:instance).proxy_feature
        configs += feature(:instance).proxy_feature.config_files(@proxy_features)
        exclude_configs += feature(:instance).proxy_feature.config_files_to_exclude(@proxy_features)
      end

      configs.compact.select { |path| Dir.glob(path).any? }
      exclude_configs.compact.select { |path| Dir.glob(path).any? }
      [configs, exclude_configs]
    end
    # rubocop:enable Metrics/AbcSize
  end
end
