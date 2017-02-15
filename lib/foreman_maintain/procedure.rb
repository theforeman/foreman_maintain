module ForemanMaintain
  class Procedure
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

    # public method to be overriden
    def run
      raise NotImplementedError
    end

    # internal method called by executor
    def __run__(_execution)
      run
    end

    def autodetect_default
      true
    end
  end
end
