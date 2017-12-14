module ForemanMaintain
  module Utils
    module Disk
      class Stats
        attr_accessor :data

        def initialize
          @data = {}
        end

        def <<(io_obj)
          data[io_obj.dir] = io_obj.performance
        end

        def stdout
          if data.keys.length > 1
            data.map { |dir, perf| "#{dir} : #{perf}" }.join("\n")
          else
            "Disk speed : #{data.values.first}"
          end
        end
      end
    end
  end
end
