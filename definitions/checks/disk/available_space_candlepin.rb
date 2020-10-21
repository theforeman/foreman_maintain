module Checks
  module Disk
    class AvailableSpaceCandlepin < ForemanMaintain::Check
      metadata do
        label :available_space_cp
        description 'Check to make sure /var/lib/candlepin has enough space'
        tags :pre_upgrade
        confine do
          feature(:candlepin) && check_min_version('candlepin', '3.1')
        end
      end

      MAX_USAGE_IN_PERCENT = 90

      def run
        assert(enough_space?, "System has more than #{MAX_USAGE_IN_PERCENT}% space used"\
               " on #{feature(:candlepin).work_dir}.\n"\
               'See https://bugzilla.redhat.com/show_bug.cgi?id=1898605')
      end

      def enough_space?
        io_obj = ForemanMaintain::Utils::Disk::IODevice.new(feature(:candlepin).work_dir)
        io_obj.space_used_in_percent < MAX_USAGE_IN_PERCENT
      end
    end
  end
end
