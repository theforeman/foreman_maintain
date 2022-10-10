module Checks
  module Disk
    class AvailableSpacePostgresql12 < ForemanMaintain::Check
      metadata do
        label :available_space_for_postgresql12
        description 'Check to make sure PostgreSQL 12 work directory has enough space for upgrade'
        confine do
          (feature(:foreman_database) || feature(:candlepin_database)) && \
            (file_exists?('/var/lib/pgsql') && \
            file_exists?('/var/opt/rh/rh-postgresql12'))
        end
      end

      def run
        assert(psql_12_available_space >= psql_9_consumed_space, warning_message, :warn => true)
      end

      def pgsql_dir(version)
        case version
        when 9
          '/var/lib/pgsql/'
        when 12
          '/var/opt/rh/rh-postgresql12/'
        end
      end

      def psql_9_consumed_space
        io_obj = ForemanMaintain::Utils::Disk::IODevice.new(pgsql_dir(9))
        io_obj.space_used
      end

      def psql_12_available_space
        io_obj = ForemanMaintain::Utils::Disk::IODevice.new(pgsql_dir(12))
        io_obj.available_space
      end

      def warning_message
        sat_version = feature(:satellite).current_version.version[0..2]
        "Satellite #{sat_version} uses PostgreSQL 12. \nThis changes PostgreSQL "\
        "work directory to #{pgsql_dir(12)}\n"\
        "The new work directory requires at least #{psql_9_consumed_space}"\
        'MiB free space for upgrade!'
      end
    end
  end
end
