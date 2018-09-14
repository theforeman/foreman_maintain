module Checks
  module Disk
    class AvailableSpace < ForemanMaintain::Check
      metadata do
        label :available_space
        description 'Check to make sure root(/) partition has enough space'
        tags :pre_upgrade
      end

      MIN_SPACE_IN_MB = 4096

      def run
        assert(enough_space?, "System has less than #{MIN_SPACE_IN_MB / 1024}GB space available"\
              ' on root(/) partition')
      end

      def enough_space?
        io_obj = ForemanMaintain::Utils::Disk::IODevice.new('/')
        io_obj.available_space > MIN_SPACE_IN_MB
      end
    end
  end
end
