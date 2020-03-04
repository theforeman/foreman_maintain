module Checks
  module Foreman
    class ValidateExternalDbVersion < ForemanMaintain::Check
      metadata do
        description 'Make sure server is running on required database version'
        tags :pre_upgrade
        label :validate_external_db_version
        confine do
          feature(:foreman_database) && !feature(:foreman_database).local? &&
            !check_min_version('foreman', '2.0')
        end
      end

      def run
        current_db_version = feature(:foreman_database).db_version
        fail!(db_upgrade_message(current_db_version)) if current_db_version.major < 12
      end

      def db_upgrade_message(db_version)
        "\n\n*** WARNING: Server is running on PostgreSQL #{db_version}.\n"\
        "*** Before performing the upgrade, please upgrade your database to PostgreSQL (>=12)\n"\
        "*** otherwise data will be lost.\n"
      end
    end
  end
end
