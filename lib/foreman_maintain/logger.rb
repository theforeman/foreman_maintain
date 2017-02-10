require 'logger'

module ForemanMaintain
  module Logger
    def logger
      @logger ||= ::Logger.new($stderr).tap do |logger|
        logger.level = ForemanMaintain.config.log_level
      end
    end
  end
end
