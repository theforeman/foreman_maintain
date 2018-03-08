require 'fileutils'
module ForemanMaintain
  class Config
    attr_accessor :pre_setup_log_messages,
                  :config_file, :definitions_dirs, :log_level, :log_dir, :log_file_size,
                  :storage_file, :backup_dir, :foreman_proxy_cert_path,
                  :db_backup_dir

    def initialize(options)
      @pre_setup_log_messages = []
      @config_file = options.fetch(:config_file, config_file_path)
      @options = load_config
      @definitions_dirs = @options.fetch(:definitions_dirs,
                                         [File.join(source_path, 'definitions')])
      load_log_configs
      load_backup_dir_paths
      @foreman_proxy_cert_path = @options.fetch(:foreman_proxy_cert_path, '/etc/foreman')
    end

    private

    def load_log_configs
      @log_level = @options.fetch(:log_level, ::Logger::DEBUG)
      @log_dir = find_dir_path(@options.fetch(:log_dir, 'log'))
      @log_file_size = @options.fetch(:log_file_size, 10_000)
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
      File.exist?(CONFIG_FILE) ? CONFIG_FILE : File.join(source_path, 'config/foreman_maintain.yml')
    end

    def source_path
      File.expand_path('../../..', __FILE__)
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
  end
end
