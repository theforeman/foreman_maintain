if RUBY_VERSION <= '1.8.7'
  require 'rubygems'
end

require 'json'

module ForemanMaintain
  require 'foreman_maintain/concerns/logger'
  require 'foreman_maintain/concerns/metadata'
  require 'foreman_maintain/concerns/system_helpers'
  require 'foreman_maintain/concerns/finders'
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
    attr_accessor :config

    def setup(configuration = {})
      self.config = Config.new(configuration)
      load_definitions
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
  end
end
