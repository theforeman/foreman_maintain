module Checks
  module Disk
    class AvailableSpacePostgresql13 < ForemanMaintain::Check
      metadata do
        label :available_space_for_postgresql13
        description 'Check to make sure PostgreSQL 13 work directory has enough space for upgrade'
        confine do
          feature(:instance).postgresql_local?
        end
      end

      def run
        assert(psql_13_available_space >= psql_12_consumed_space, warning_message)
      end

      def pgsql_dir(version)
        case version
        when 12
          '/var/lib/pgsql/data'
        when 13
          '/var/lib/pgsql'
        end
      end

      def psql_12_consumed_space
        io_obj = ForemanMaintain::Utils::Disk::IODevice.new(pgsql_dir(12))
        io_obj.space_used
      end

      def psql_13_available_space
        io_obj = ForemanMaintain::Utils::Disk::IODevice.new(pgsql_dir(13))
        io_obj.available_space
      end

      def warning_message
        "PostgreSQL will be upgraded from 12 to 13. \n" \
        "During the upgrade a backup is created in /var/lib/pgsql/data-old and requires " \
        "at least #{psql_12_consumed_space} MiB free space."
      end
    end
  end
end
