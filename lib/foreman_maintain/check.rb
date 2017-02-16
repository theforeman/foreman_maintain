module ForemanMaintain
  class Check < Executable
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders

    attr_accessor :associated_feature

    class Fail < StandardError
    end

    def initialize(associated_feature)
      @associated_feature = associated_feature
    end

    def assert(condition, error_message)
      raise Fail, error_message unless condition
    end

    # public method to be overriden
    def run
      raise NotImplementedError
    end

    # internal method called by executor
    def __run__(execution)
      super
    rescue Fail => e
      execution.status = :fail
      execution.output << e.message
    end
  end
end
