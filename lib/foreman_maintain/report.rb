module ForemanMaintain
  class Report < Executable
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders

    # public method to be overriden
    def run
      raise NotImplementedError
    end

    def to_h
      raise NotImplementedError
    end
  end
end
