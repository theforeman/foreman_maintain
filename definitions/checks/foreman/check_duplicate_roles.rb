module Checks
  module Foreman
    class CheckDuplicateRoles < ForemanMaintain::Check
      metadata do
        label :duplicate_roles
        for_feature :foreman_database
        description 'Check for duplicate roles from DB'
        tags :pre_upgrade
        confine do
          check_min_version('foreman', '1.11')
        end
      end

      def run
        duplicate_roles = find_duplicate_roles
        assert(
          duplicate_roles.empty?,
          'Duplicate entries found for role(s) in your DB',
          :next_steps => [
            Procedures::Foreman::RemoveObsoleteRoles.new,
            Procedures::KnowledgeBaseArticle.new(
              :doc => 'fix_db_migrate_failure_on_duplicate_roles'
            )
          ]
        )
      end

      def find_duplicate_roles
        feature(:foreman_database).query(self.class.query_to_get_duplicate_roles)
      end

      def self.query_to_get_duplicate_roles
        <<-SQL
          SELECT r.id FROM roles r JOIN (
            SELECT name, COUNT(*) FROM roles GROUP BY name HAVING count(*) > 1
          ) dr ON r.name = dr.name ORDER BY r.name
        SQL
      end
    end
  end
end
