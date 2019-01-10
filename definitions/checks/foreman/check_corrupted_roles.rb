module Checks
  module Foreman
    class CheckCorruptedRoles < ForemanMaintain::Check
      metadata do
        label :corrupted_roles
        for_feature :foreman_database
        description 'Check for roles that have filters with multiple resources attached'
        tags :pre_upgrade
      end

      def run
        items = find_filter_permissions
        assert(items.empty?,
               'There are user roles with inconsistent filters',
               :next_steps => Procedures::Foreman::FixCorruptedRoles.new)
      end

      def find_filter_permissions
        feature(:foreman_database).query(self.class.inconsistent_filter_perms)
      end

      def self.inconsistent_filter_perms
        subquery = <<-SQL
          SELECT filters.id AS filter_id,
                 filters.role_id,
                 filters.search,
                 filters.taxonomy_search,
                 filters.override,
                 filterings.id AS filtering_id,
                 permissions.id AS permission_id,
                 permissions.name AS permission_name,
                 permissions.resource_type
          FROM filters INNER JOIN filterings ON filters.id = filterings.filter_id
                       INNER JOIN permissions ON permissions.id = filterings.permission_id
        SQL

        <<-SQL
          SELECT DISTINCT first.filter_id,
                          first.role_id,
                          first.filtering_id,
                          first.permission_id,
                          first.permission_name,
                          first.resource_type,
                          first.search,
                          first.taxonomy_search,
                          first.override
          FROM (#{subquery}) first JOIN (#{subquery}) second
            ON first.filter_id = second.filter_id AND
              ((first.resource_type IS NOT NULL AND second.resource_type IS NULL)
                OR (first.resource_type IS NULL AND second.resource_type IS NOT NULL)
                OR (first.resource_type != second.resource_type))
        SQL
      end
    end
  end
end
