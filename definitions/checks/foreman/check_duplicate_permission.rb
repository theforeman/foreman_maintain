module Checks
  module Foreman
    class CheckDuplicatePermission < ForemanMaintain::Check
      metadata do
        label :duplicate_permission
        for_feature :foreman_database
        description 'Check for duplicate permission from database'
        tags :default
      end

      def run
        duplicate_permissions = find_duplicate_permission
        assert(
          duplicate_permissions.empty?,
          'Duplicate permissions in your DB',
          :next_steps => [
            Procedures::Foreman::RemoveDuplicatePermissions.new
          ]
        )
      end

      def find_duplicate_permission
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
