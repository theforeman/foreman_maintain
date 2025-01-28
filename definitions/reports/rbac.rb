module Reports
  class RBAC < ForemanMaintain::Report
    metadata do
      description 'Checks the RBAC use'
    end

    TAXONOMY_TYPES = %w[Organization Location].freeze

    # How many users do you have in the system?
    # How many non-admin users do you have?
    # How many custom roles did you create and assigned to users?
    def run
      self.data = {}

      data.merge!(user_counts)
      data.merge!(custom_roles_counts)
      data.merge!(taxonomy_counts)
      data.merge!(taxonomy_ignore_type_uses)
    end

    def user_counts
      users = sql_count("users" +
                        " INNER JOIN auth_sources ON auth_sources.id = users.auth_source_id" +
                        " WHERE auth_sources.name != 'Hidden'")

      non_admin_users = sql_count("users" +
        " LEFT OUTER JOIN cached_usergroup_members" +
        "   ON cached_usergroup_members.user_id = users.id" +
        " LEFT OUTER JOIN usergroups ON usergroups.id = cached_usergroup_members.usergroup_id" +
        " INNER JOIN auth_sources ON auth_sources.id = users.auth_source_id" +
        " WHERE ((users.admin = FALSE OR users.admin IS NULL)" +
        "        AND (usergroups.admin = FALSE OR usergroups.admin IS NULL))" +
        " AND auth_sources.name != 'Hidden'")

      { 'users_count' => users, 'non_admin_users_count' => non_admin_users }
    end

    def custom_roles_counts
      role_ids = query("SELECT id FROM roles WHERE roles.builtin != 2 AND roles.origin IS NULL")
      roles_count = role_ids.size
      role_ids = role_ids.flat_map(&:values)
      assigned_count = if role_ids.empty?
                         0
                       else
                         sql = "cached_user_roles" +
                               "WHERE cached_user_roles.role_id IN (#{role_ids.join(',')})"
                         sql_count(sql)
                       end

      { 'custom_roles_count' => roles_count, 'assigned_custom_roles_count' => assigned_count }
    end

    def taxonomy_counts
      TAXONOMY_TYPES.to_h do |t|
        ["#{t.downcase}s_count", sql_count("taxonomies WHERE type = '#{t}'")]
      end
    end

    def taxonomy_ignore_type_uses
      TAXONOMY_TYPES.to_h do |t|
        count = sql_count("taxonomies" +
                          " WHERE type = '#{t}'" +
                          "   AND ignore_types IS NOT NULL")
        ["#{t.downcase}_ignore_types_used", count.positive?]
      end
    end
  end
end
