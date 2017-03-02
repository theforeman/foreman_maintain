module ForemanMaintain
  module Utils
    module Disk
      class NilDevice
        NULL = 'NULL'.freeze

        attr_accessor :dir, :name, :unit, :read_speed

        def initialize
          @dir = NULL
          @name = NULL
          @unit = NULL
          @read_speed = NULL
        end
      end
    end
  end
end
