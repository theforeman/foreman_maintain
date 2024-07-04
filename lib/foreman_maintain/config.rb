require 'fileutils'
module ForemanMaintain
  class Config
    attr_accessor :pre_setup_log_messages,
      :config_file, :definitions_dirs, :log_level, :log_dir, :log_file_size,
      :log_filename, :storage_file, :backup_dir, :foreman_proxy_cert_path,
      :db_backup_dir, :completion_cache_file, :disable_commands, :manage_crond,
      :foreman_url, :foreman_port

    def initialize(options)
      @pre_setup_log_messages = []
      @config_file = options.fetch(:config_file, config_file_path)
      @options = load_config
      @definitions_dirs = @options.fetch(:definitions_dirs,
        [File.join(source_path, 'definitions')])
      load_log_configs
      load_backup_dir_paths
      load_cron_option
      @foreman_proxy_cert_path = @options.fetch(:foreman_proxy_cert_path, '/etc/foreman')
      @completion_cache_file = File.expand_path(
        @options.fetch(:completion_cache_file, '~/.cache/foreman_maintain_completion.yml')
      )
      @disable_commands = @options.fetch(:disable_commands, [])
      @foreman_url = @options.fetch(:foreman_url) { `hostname -f`.chomp }
      @foreman_port = @options.fetch(:foreman_port, 443)
    end

    def use_color?
      ENV['TERM'] && ENV.fetch('NO_COLOR', '') == '' && \
        system('command -v tput', out: File.open('/dev/null')) && `tput colors`.to_i > 0
    end

    private

    def load_log_configs
      @log_level = @options.fetch(:log_level, ::Logger::INFO)
      @log_dir = find_dir_path(@options.fetch(:log_dir, 'log'))
      @log_file_size = @options.fetch(:log_file_size, 10_000)
      # Note - If timestamp added to filename then number of log files i.e second
      # argument to Logger.new will not work as expected
      @log_filename = File.expand_path("#{@log_dir}/foreman-maintain.log")
    end

    def load_backup_dir_paths
      @storage_file = @options.fetch(:storage_file, 'data.yml')
      @backup_dir = find_dir_path(
        @options.fetch(:backup_dir, '/var/lib/foreman-maintain')
      )
      @db_backup_dir = find_dir_path(
        @options.fetch(:db_backup_dir, '/var/lib/foreman-maintain/db-backups')
      )
    end

    def load_cron_option
      opt_val = @options.fetch(:manage_crond, false)
      @manage_crond = boolean?(opt_val) ? opt_val : false
    end

    def load_config
      if File.exist?(config_file)
        YAML.load(File.open(config_file)) || {}
      else
        @pre_setup_log_messages <<
          "Config file #{config_file} not found, using default configuration"
        {}
      end
    rescue StandardError => e
      raise "Couldn't load configuration file. Error: #{e.message}"
    end

    def config_file_path
      if defined?(CONFIG_FILE) && File.exist?(CONFIG_FILE)
        CONFIG_FILE
      else
        File.join(source_path, 'config/foreman_maintain.yml')
      end
    end

    def source_path
      File.expand_path('../..', __dir__)
    end

    def find_dir_path(dir_path_str)
      dir_path = File.expand_path(dir_path_str)
      begin
        FileUtils.mkdir_p(dir_path, :mode => 0o750) unless File.exist?(dir_path)
      rescue StandardError => e
        warn "No permissions to create dir #{dir_path_str}"
        warn e.message.inspect
      end
      dir_path
    end

    def boolean?(value)
      [true, false].include? value
    end
  end
end
