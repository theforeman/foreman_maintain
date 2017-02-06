module ForemanMaintain
  require 'foreman_maintain/top_level_modules'
  require 'foreman_maintain/logger'
  require 'foreman_maintain/system_helpers'
  require 'foreman_maintain/feature'

  def self.definitions_dirs
    [File.expand_path('../../definitions', __FILE__)]
  end

  def self.load_definitions
    definitions_dirs.each do |definitions_dir|
      $LOAD_PATH.unshift(definitions_dir)
      Dir.glob(File.join(definitions_dir, '**', '*.rb')).each { |f| require f }
    end
  end

  def self.detect_features
    Feature::Detector.new.run
  end
end