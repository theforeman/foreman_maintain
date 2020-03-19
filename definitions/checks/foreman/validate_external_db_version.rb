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
        product_name = feature(:instance).product_name

        "\n\n*** ERROR: Server is running on PostgreSQL #{db_version} database.\n"\
        "*** Newer version of #{product_name} supports only PostgreSQL version 12.\n"\
        "*** Before proceeding further, you must upgrade database to PostgreSQL 12.\n"
      end
    end
  end
end
