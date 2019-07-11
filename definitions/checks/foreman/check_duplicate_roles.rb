module Checks
  module Foreman
    class CheckDuplicateRoles < ForemanMaintain::Check
      metadata do
        label :duplicate_roles
        for_feature :foreman_database
        description 'Check for duplicate roles from DB'
        tags :pre_upgrade
        confine do
          check_max_version('foreman', '1.20')
        end
      end

      def run
        duplicate_roles = find_duplicate_roles
        roles_names = duplicate_roles.map { |r| r['name'] }.uniq
        assert(
          duplicate_roles.empty?,
          "Duplicate entries found for role(s) - #{roles_names.join(', ')} in your DB",
          :next_steps => [
            Procedures::Foreman::RemoveDuplicateObsoleteRoles.new,
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
          SELECT r.id, r.name FROM roles r JOIN (
            SELECT name, COUNT(*) FROM roles GROUP BY name HAVING count(*) > 1
          ) dr ON r.name = dr.name ORDER BY r.name
        SQL
      end
    end
  end
end
