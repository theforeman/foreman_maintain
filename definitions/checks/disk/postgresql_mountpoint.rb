module Checks
  module Disk
    class PostgresqlMountpoint < ForemanMaintain::Check
      metadata do
        label :postgresql_mountpoint
        description 'Check to make sure PostgreSQL data is not on an own mountpoint'
        confine do
          feature(:instance).postgresql_local? && ForemanMaintain.el?
        end
      end

      def run
        assert(psql_dir_device == psql_data_dir_device, warning_message)
      end

      def psql_dir_device
        device = ForemanMaintain::Utils::Disk::Device.new('/var/lib/pgsql')
        device.name
      end

      def psql_data_dir_device
        device = ForemanMaintain::Utils::Disk::Device.new('/var/lib/pgsql/data')
        device.name
      end

      def warning_message
        <<~MSG
          PostgreSQL data (/var/lib/pgsql/data) is on a different device than /var/lib/pgsql.
          This is not supported and breaks PostgreSQL upgrades.
          Please ensure PostgreSQL data is on the same mountpoint as the /var/lib/pgsql.
        MSG
      end
    end
  end
end
