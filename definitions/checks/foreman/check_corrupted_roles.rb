module Checks
  module Foreman
    class CheckCorruptedRoles < ForemanMaintain::Check
      metadata do
        label :corrupted_roles
        for_feature :foreman_database
        description 'Check for roles that have filters with multiple resources attached'
        tags :pre_upgrade
        confine do
          check_min_version('foreman', '1.15')
        end
      end

      def run
        items = find_filter_permissions
        assert(items.empty?,
               error_message(items),
               :next_steps => Procedures::Foreman::FixCorruptedRoles.new)
      end

      def error_message(items)
        roles = items.map { |item| item['role_name'] }.uniq
        'There are filters having permissions with multiple resource types. ' \
        'Roles with such filters are:' \
        "\n#{roles.join("\n")}"
      end

      def find_filter_permissions
        feature(:foreman_database).query(self.class.inconsistent_filter_perms)
      end

      # rubocop:disable Metrics/MethodLength
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
                 permissions.resource_type,
                 roles.name AS role_name
          FROM filters INNER JOIN filterings ON filters.id = filterings.filter_id
                       INNER JOIN permissions ON permissions.id = filterings.permission_id
                       INNER JOIN roles ON filters.role_id = roles.id
        SQL

        <<-SQL
          SELECT DISTINCT first.filter_id,
                          first.role_id,
                          first.role_name,
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
      # rubocop:enable Metrics/MethodLength
    end
  end
end
