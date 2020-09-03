module Checks
  module Foreman
    class CheckDuplicatePermissions < ForemanMaintain::Check
      metadata do
        label :duplicate_permissions
        for_feature :foreman_database
        description 'Check for duplicate permissions from database'
        tags :pre_upgrade
      end

      def run
        duplicate_permissions = find_duplicate_permissions
        assert(
          duplicate_permissions.empty?,
          'Duplicate permissions in your database',
          :next_steps => [
            Procedures::Foreman::RemoveDuplicatePermissions.new
          ]
        )
      end

      def find_duplicate_permissions
        feature(:foreman_database).query(self.class.query_to_get_duplicate_permission)
      end

      def self.query_to_get_duplicate_permission
        <<-SQL
          SELECT id,name FROM permissions p WHERE (SELECT count(name) FROM permissions pr WHERE p.name =pr.name) > 1
        SQL
      end
    end
  end
end
