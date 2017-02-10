require 'logger'

module ForemanMaintain
  module Logger
    def logger
      @logger ||= ::Logger.new($stderr)
    end
  end
end
