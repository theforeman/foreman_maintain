module Checks
  module Foreman
    class CheckExternalDbEvrPermissions < ForemanMaintain::Check
      metadata do
        label :external_db_evr_permissions
        for_feature :foreman_database
        description 'Check that external databases have proper EVR extension permissions'
        tags :pre_upgrade
        confine do
          feature(:foreman_database) && !feature(:foreman_database).local? && feature(:katello)
        end
      end

      def run
        return true unless evr_exists?

        error_msg = 'The evr extension is not owned by the foreman database owner. ' \
              'Please run the following command on the external foreman database to fix it: ' \
              'UPDATE pg_extension SET extowner = (SELECT oid FROM pg_authid WHERE ' \
              "rolname='#{foreman_db_user}') WHERE extname='evr';"
        fail!(error_msg) unless foreman_owns_evr?
      end

      private

      def foreman_db_user
        feature(:foreman_database).configuration['username'] || 'foreman'
      end

      def evr_exists?
        evr_exists = feature(:foreman_database).query(query_for_evr_existence)
        return false if evr_exists.empty?
        return evr_exists.first['evr_exists'] == '1'
      end

      def foreman_owns_evr?
        evr_owned_by_postgres = feature(:foreman_database).query(query_if_postgres_owns_evr)
        unless evr_owned_by_postgres.empty?
          return evr_owned_by_postgres.first['evr_owned_by_postgres'] == '0'
        end
        failure_msg = 'Could not determine if the evr extension is owned by the ' \
                'foreman database owner. Check that the foreman database is accessible ' \
                "and that the database connection configuration is up to date."
        fail!(failure_msg)
      end

      def query_for_evr_existence
        <<-SQL
          SELECT 1 AS evr_exists FROM pg_extension WHERE extname = 'evr'
        SQL
      end

      def query_if_postgres_owns_evr
        <<-SQL
          SELECT CASE WHEN r.rolname = '#{foreman_db_user}' THEN 0 ELSE 1 END AS evr_owned_by_postgres
          FROM pg_extension e JOIN pg_roles r ON e.extowner = r.oid WHERE e.extname = 'evr'
        SQL
      end
    end
  end
end
