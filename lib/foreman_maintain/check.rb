module ForemanMaintain
  class Check
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata

    class Fail < StandardError
    end

    def initialize
      @detector = ForemanMaintain.features_detector
    end

    def feature(name)
      @detector.feature(name)
    end

    def assert(condition, error_message)
      raise Fail, error_message unless condition
    end

    # internal method called by executor
    def __run__(execution)
      self.run
    rescue Fail => e
      execution.status = :fail
      execution.output << e.message
    end
  end
end
