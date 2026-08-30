module Checks
  module Disk
    class AvailableSpace < ForemanMaintain::Check
      metadata do
        label :available_space
        description 'Check if /var/cache partition has enough space for transaction'
        tags :pre_upgrade
      end

      MIN_SPACE_IN_MB = 4096

      def run
        assert(enough_space?, "System has less than #{MIN_SPACE_IN_MB / 1024}GB space available"\
              ' on /var/cache partition')
      end

      def enough_space?
        device = ForemanMaintain::Utils::Disk::Device.new('/var/cache').name
        io_obj = ForemanMaintain::Utils::Disk::IODevice.new(device)
        io_obj.available_space > MIN_SPACE_IN_MB
      end
    end
  end
end
