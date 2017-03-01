if RUBY_VERSION <= '1.8.7'
  require 'rubygems'
end

require 'forwardable'
require 'json'
require 'logger'

module ForemanMaintain
  require 'foreman_maintain/concerns/logger'
  require 'foreman_maintain/concerns/finders'
  require 'foreman_maintain/concerns/metadata'
  require 'foreman_maintain/concerns/system_helpers'
  require 'foreman_maintain/top_level_modules'
  require 'foreman_maintain/config'
  require 'foreman_maintain/detector'
  require 'foreman_maintain/feature'
  require 'foreman_maintain/executable'
  require 'foreman_maintain/check'
  require 'foreman_maintain/procedure'
  require 'foreman_maintain/scenario'
  require 'foreman_maintain/runner'
  require 'foreman_maintain/reporter'
  require 'foreman_maintain/utils'

  class << self
    attr_accessor :config, :logger

    def setup(configuration = {})
      self.config = Config.new(configuration)
      load_definitions
      init_logger
    end

    def load_definitions
      # we need to add the load paths first, in case there is crossreferencing
      # between the definitions directories
      $LOAD_PATH.concat(config.definitions_dirs)
      config.definitions_dirs.each do |definitions_dir|
        Dir.glob(File.join(definitions_dir, '**', '*.rb')).each { |f| require f }
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
        logger.level = config.log_level || Logger::DEBUG
        logger.datetime_format = '%Y-%m-%d %H:%M:%S%z '
      end
    end
  end
end
