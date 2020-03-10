module Procedures::Backup
  class ConfigFiles < ForemanMaintain::Procedure
    MAX_RETRIES = 3
    RETRY_DELAY = 10

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
      param :online_backup, 'The config files are being prepared for an online backup',
            :flag => true, :default => false
    end

    # rubocop:disable Metrics/MethodLength
    def run
      logger.debug("Invoking tar from #{FileUtils.pwd}")
      tar_cmd = tar_command
      attempt_no = 1
      loop do
        runner = nil
        with_spinner('Collecting config files to backup') do
          runner = execute_runner(tar_cmd, :valid_exit_statuses => [0, 1])
        end
        break if runner.exit_status == 0 || @ignore_changed_files

        puts "WARNING: Attempt #{attempt_no}/#{MAX_RETRIES} to collect all config files failed!"
        puts 'Some files were modified during creation of the archive.'
        if attempt_no == MAX_RETRIES
          raise runner.execution_error
        else
          attempt_no += 1
          FileUtils.rm_rf(tarball_path)
          puts "Waiting #{RETRY_DELAY} seconds before re-try"
          sleep(RETRY_DELAY)
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/AbcSize
    def config_files
      configs = []
      exclude_configs = []
      ForemanMaintain.available_features.each do |feature|
        # exclude proxy as it has special handling later
        next if [:foreman_proxy, :capsule].include?(feature.label)

        configs += feature.config_files
        exclude_configs += feature.config_files_to_exclude
        exclude_configs += feature.config_files_exclude_for_online if @online_backup
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

    private

    def tar_command
      increments_path = File.join(@backup_dir, '.config.snar')
      configs, to_exclude = config_files

      feature(:tar).tar_command(
        :command => 'create', :gzip => true, :archive => tarball_path,
        :listed_incremental => increments_path, :ignore_failed_read => true,
        :exclude => to_exclude, :files => configs.join(' ')
      )
    end

    def tarball_path
      @tarball_path ||= File.join(@backup_dir, 'config_files.tar.gz')
    end
  end
end
