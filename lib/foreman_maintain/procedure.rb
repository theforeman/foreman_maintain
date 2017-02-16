module ForemanMaintain
  class Procedure < Executable
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders
  end
end
