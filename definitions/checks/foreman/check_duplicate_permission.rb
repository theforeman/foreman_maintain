module Checks
  module Foreman
    class CheckDuplicatePermission < ForemanMaintain::Check
      metadata do
        label :duplicate_permission
        for_feature :foreman_database
        description 'Check for duplicate permission from DB'
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
          SELECT count(*), name, resource_type  FROM permissions GROUP BY name, resource_type HAVING count(*) > 1
        SQL
      end
    end
  end
end
