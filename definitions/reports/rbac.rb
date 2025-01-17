module Checks
  module Report
    class RBAC < ForemanMaintain::Report
      metadata do
        description 'Checks the RBAC use'
      end

      # How many users do you have in the system?
      # How many non-admin users do you have?
      # How many custom roles did you create and assigned to users?
      # rubocop:disable Layout/LineLength
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def run
        result = {}

        count = sql_count("users" +
                          " INNER JOIN auth_sources ON auth_sources.id = users.auth_source_id" +
                          " WHERE auth_sources.name != 'Hidden'")
        result["users_count"] = count

        count = sql_count("users" +
          " LEFT OUTER JOIN cached_usergroup_members ON cached_usergroup_members.user_id = users.id" +
          " LEFT OUTER JOIN usergroups ON usergroups.id = cached_usergroup_members.usergroup_id" +
          " INNER JOIN auth_sources ON auth_sources.id = users.auth_source_id" +
          " WHERE ((users.admin = FALSE OR users.admin IS NULL) AND (usergroups.admin = FALSE OR usergroups.admin IS NULL))" +
          " AND auth_sources.name != 'Hidden'")
        result["non_admin_users_count"] = count

        role_ids = feature(:foreman_database).query("SELECT id FROM roles WHERE roles.builtin != 2 AND roles.origin IS NULL")
        result["custom_roles_count"] = role_ids.size
        role_ids = role_ids.flat_map(&:values)
        count = sql_count("cached_user_roles WHERE cached_user_roles.role_id IN (#{role_ids.join(',')})")
        result["assigned_custom_roles_count"] = count

        count = sql_count("taxonomies" +
                            " WHERE taxonomies.type = 'Organization'")
        result["organizations_count"] = count

        count = sql_count("taxonomies" +
                            " WHERE taxonomies.type = 'Location'")
        result["locations_count"] = count

        count = sql_count("taxonomies" +
                            " WHERE taxonomies.type = 'Organization'" +
                            " AND taxonomies.ignore_types IS NOT NULL")
        result["organization_ignore_types_used"] = count > 0

        count = sql_count("taxonomies" +
                            " WHERE taxonomies.type = 'Location'" +
                            " AND taxonomies.ignore_types IS NOT NULL")
        result["location_ignore_types_used"] = count > 0

        self.data = result
      end
      # rubocop:enable Layout/LineLength
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize
    end
  end
end
