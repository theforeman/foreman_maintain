module ForemanMaintain
  class Check
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders

    attr_accessor :associated_feature

    module DSL
      # Specify what feature the check is related to.
      def for_feature(feature_label)
        metadata[:for_feature] = feature_label
        confine do
          feature(feature_label)
        end
      end
    end
    extend DSL

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
      run
    rescue Fail => e
      execution.status = :fail
      execution.output << e.message
    end

    def autodetect_default
      true
    end
  end
end
