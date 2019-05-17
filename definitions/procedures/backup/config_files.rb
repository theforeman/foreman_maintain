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
        configs = config_files.join(' ')
        statuses = @ignore_changed_files ? [0, 1] : [0]
        execute!("tar --selinux --create --gzip --file=#{tarball} " \
          "--listed-incremental=#{increments} --ignore-failed-read " \
          "#{configs}", :valid_exit_statuses => statuses)
      end
    end

    def config_files
      configs = []
      # exclude proxy as it has special handling later
      features = ForemanMaintain.available_features - [feature(:foreman_proxy)]
      configs += features.inject([]) { |files, feature| files + feature.config_files }
      configs += feature(:foreman_proxy).config_files(@proxy_features) if feature(:foreman_proxy)
      configs.compact.select { |path| Dir.glob(path).any? }
    end
  end
end
