module ForemanMaintain
  class Check
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata

    class Fail < StandardError
    end

    def assert(condition, error_message)
      raise Fail, error_message unless condition
    end
  end
end
