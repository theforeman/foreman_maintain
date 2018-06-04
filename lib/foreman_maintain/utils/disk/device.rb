module ForemanMaintain
  module Utils
    module Disk
      class Device
        extend Forwardable

        include ForemanMaintain::Concerns::SystemHelpers

        EXTERNAL_MOUNT_TYPE = %w[fuseblk nfs].freeze

        attr_accessor :dir, :name, :unit, :read_speed

        attr_reader :io_device

        def_delegators :io_device, :unit, :read_speed

        def initialize(dir)
          @dir = dir
          @name = find_device
          logger.info "#{dir} is externally mounted" if externally_mounted?
          @io_device = IODevice.new(dir)
        end

        def slow_disk_error_msg
          "Slow disk detected #{dir} mounted on #{name}.
             Actual disk speed: #{read_speed} #{default_unit}
             Expected disk speed: #{expected_io} #{default_unit}."
        end

        def performance
          "#{read_speed} #{unit}"
        end

        private

        def externally_mounted?
          device_type = execute("stat -f -c %T #{dir}")
          EXTERNAL_MOUNT_TYPE.include?(device_type)
        end

        def find_device
          execute("df -h #{dir} | sed -n '2p' | awk '{print $1}'")
        end

        def default_unit
          Checks::Disk::Performance::DEFAULT_UNIT
        end

        def expected_io
          Checks::Disk::Performance::EXPECTED_IO
        end
      end
    end
  end
end
