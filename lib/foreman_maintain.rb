module ForemanMaintain
  require 'foreman_maintain/concerns/logger'
  require 'foreman_maintain/concerns/metadata'
  require 'foreman_maintain/concerns/system_helpers'
  require 'foreman_maintain/top_level_modules'
  require 'foreman_maintain/config'
  require 'foreman_maintain/filter'
  require 'foreman_maintain/feature'
  require 'foreman_maintain/check'

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

    def features_detector
      @features_detector ||= Feature::Detector.new
    end

    def detect_features
      features_detector.available_features
    end
  end
end
