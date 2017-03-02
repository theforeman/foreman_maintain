module ForemanMaintain
  module Utils
    module Disk
      class Device
        include ForemanMaintain::Concerns::SystemHelpers

        EXTERNAL_MOUNT_TYPE = %w(fuseblk nfs).freeze

        attr_accessor :dir, :name, :unit, :read_speed

        attr_reader :io_device

        def initialize(dir)
          @dir = dir
          @name = find_device
          @io_device = init_io_device
        end

        def unit
          @unit ||= io_device.unit
        end

        def read_speed
          @read_speed ||= io_device.read_speed
        end

        def slow_disk_error_msg
          "Slow disk detected #{dir} mounted on #{name}.
             Actual disk speed: #{read_speed} #{default_unit}
             Expected disk speed: #{expected_io} #{default_unit}."
        end

        private

        def init_io_device
          if externally_mounted?
            IO::FileSystem
          else
            IO::BlockDevice
          end.new(dir, name)
        end

        def externally_mounted?
          device_type = execute("stat -f -c %T #{dir}")
          EXTERNAL_MOUNT_TYPE.include?(device_type)
        end

        def find_device
          execute("df -h #{dir} | sed -n '2p' | awk '{print $1}'")
        end

        def default_unit
          Checks::DiskSpeedMinimal::DEFAULT_UNIT
        end

        def expected_io
          Checks::DiskSpeedMinimal::EXPECTED_IO
        end
      end
    end
  end
end
