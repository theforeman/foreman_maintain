if RUBY_VERSION <= '1.8.7'
  require 'rubygems'
end

require 'forwardable'
require 'json'
require 'logger'
require 'yaml'

module ForemanMaintain
  require 'foreman_maintain/core_ext'
  require 'foreman_maintain/concerns/logger'
  require 'foreman_maintain/concerns/finders'
  require 'foreman_maintain/concerns/metadata'
  require 'foreman_maintain/concerns/system_helpers'
  require 'foreman_maintain/concerns/hammer'
  require 'foreman_maintain/top_level_modules'
  require 'foreman_maintain/yaml_storage'
  require 'foreman_maintain/config'
  require 'foreman_maintain/detector'
  require 'foreman_maintain/param'
  require 'foreman_maintain/feature'
  require 'foreman_maintain/executable'
  require 'foreman_maintain/check'
  require 'foreman_maintain/procedure'
  require 'foreman_maintain/scenario'
  require 'foreman_maintain/runner'
  require 'foreman_maintain/reporter'
  require 'foreman_maintain/utils'
  require 'foreman_maintain/error'

  class << self
    attr_accessor :config, :logger

    LOGGER_LEVEL_MAPPING = {
      'debug' => ::Logger::DEBUG,
      'info' => ::Logger::INFO,
      'warn' => ::Logger::WARN,
      'error' => ::Logger::ERROR,
      'fatal' => ::Logger::FATAL,
      'unknown' => ::Logger::UNKNOWN
    }.freeze

    def setup(options = {})
      # using a queue, we can log the messages which are generated before initializing logger
      @pre_setup_log_messages = []
      custom_configs = load_custom_configs(options[:config_file])
      self.config = Config.new(custom_configs)
      load_definitions
      init_logger
    end

    def config_file
      File.expand_path('../config/foreman_maintain.yml', File.dirname(__FILE__))
    end

    def load_definitions
      # we need to add the load paths first, in case there is crossreferencing
      # between the definitions directories
      $LOAD_PATH.concat(config.definitions_dirs)
      config.definitions_dirs.each do |definitions_dir|
        file_paths = File.expand_path(File.join(definitions_dir, '**', '*.rb'))
        Dir.glob(file_paths).each { |f| require f }
      end
    end

    def detector
      @detector ||= Detector.new
    end

    def available_features(*args)
      detector.available_features(*args)
    end

    def available_scenarios(*args)
      detector.available_scenarios(*args)
    end

    def available_checks(*args)
      detector.available_checks(*args)
    end

    def available_procedures(*args)
      detector.available_procedures(*args)
    end

    def init_logger
      # Note - If timestamp added to filename then number of log files i.e second
      # argument to Logger.new will not work as expected
      filename = File.expand_path("#{config.log_dir}/foreman-maintain.log")
      @logger = Logger.new(filename, 10, 10_240_000).tap do |logger|
        logger.level = LOGGER_LEVEL_MAPPING[config.log_level] || Logger::DEBUG
        logger.datetime_format = '%Y-%m-%d %H:%M:%S%z '
      end
      pickup_log_messages
    end

    def pickup_log_messages
      return if @pre_setup_log_messages.empty?
      @pre_setup_log_messages.each { |msg| logger.info msg }
      @pre_setup_log_messages.clear
    end

    def load_custom_configs(file_path)
      file_path ||= ''
      custom_configs = {}
      if File.exist?(file_path)
        custom_configs = YAML.load(File.open(file_path)) || {}
      else
        @pre_setup_log_messages << "Config file #{file_path} not found, using default configuration"
      end
      custom_configs
    rescue => e
      raise "Couldn't load configuration file. Error: #{e.message}"
    end

    def storage(label)
      ForemanMaintain::YamlStorage.load(label)
    rescue => e
      logger.error "Invalid Storage label i.e #{label}. Error - #{e.message}"
    end
  end
end
