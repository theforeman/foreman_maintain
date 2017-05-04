require 'fileutils'
module ForemanMaintain
  class Config
    attr_accessor :pre_setup_log_messages,
                  :config_file, :definitions_dirs, :log_level, :log_dir, :storage_file

    def initialize(options)
      @pre_setup_log_messages = []
      @config_file = options.fetch(:config_file, default_config_file)
      @options = load_config
      @definitions_dirs = @options.fetch(:definitions_dirs,
                                         [File.join(source_path, 'definitions')])

      @log_level = @options.fetch(:log_level, ::Logger::DEBUG)
      @log_dir = find_log_dir_path(@options.fetch(:log_dir, 'log'))
      @storage_file = @options.fetch(:storage_file, 'data.yml')
    end

    private

    def load_config
      if File.exist?(config_file)
        YAML.load(File.open(config_file)) || {}
      else
        @pre_setup_log_messages <<
          "Config file #{config_file} not found, using default configuration"
        {}
      end
    rescue => e
      raise "Couldn't load configuration file. Error: #{e.message}"
    end

    def default_config_file
      File.join(source_path, 'config/foreman_maintain.yml')
    end

    def source_path
      File.expand_path('../../..', __FILE__)
    end

    def find_log_dir_path(log_dir)
      log_dir_path = File.expand_path(log_dir)
      begin
        FileUtils.mkdir_p(log_dir_path, :mode => 0o750) unless File.exist?(log_dir_path)
      rescue => e
        $stderr.puts "No permissions to create log dir #{log_dir}"
        $stderr.puts e.message.inspect
      end
      log_dir_path
    end
  end
end
