module ForemanMaintain
  module Utils
    module Disk
      module IO
        class BlockDevice
          include ForemanMaintain::Concerns::SystemHelpers

          attr_accessor :dir, :unit, :read_speed, :name

          def initialize(dir, name = Disk::Device.new('/var').name)
            @dir = dir
            @name = name
          end

          def read_speed
            @read_speed ||= extract_speed(hdparm)
          end

          def unit
            @unit ||= extract_unit(hdparm)
          end

          private

          def hdparm
            @stdout ||= execute("hdparm -t #{name} | awk 'NF'")
          end

          def extract_unit(stdout)
            stdout.split(' ').last
          end

          def extract_speed(stdout)
            stdout.split(' ').reverse[1].to_i
          end
        end
      end
    end
  end
end
