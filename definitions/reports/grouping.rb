module Reports
  class Grouping < ForemanMaintain::Report
    metadata do
      description 'Check how resources are grouped'
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def run
      self.data = {}
      data_field('host_collections_count') { sql_count('katello_host_collections') }

      data_field('host_collections_with_limit_count') do
        sql_count("katello_host_collections
                   WHERE unlimited_hosts = 'f'")
      end

      hostgroup = sql_count('hostgroups')
      hostgroup_nest_level = sql_as_count(
        "COALESCE(MAX((CHAR_LENGTH(ancestry) - CHAR_LENGTH(REPLACE(ancestry, '/', '')))) + 2, 1)",
        'hostgroups'
      )
      data['hostgroup_nesting'] = hostgroup_nest_level > 1
      data['hostgroup_max_nesting_level'] = hostgroup.zero? ? 0 : hostgroup_nest_level

      data_field('use_selectable_columns') { sql_count('table_preferences') > 0 }

      if table_exists('config_groups')
        data_field('config_group_count') { sql_count('config_groups') }
      end

      data_field('usergroup_max_nesting_level') { usergroup_max_nesting_level }

      usergroup_roles_stats = usergroup_roles_statistics
      data['user_group_roles_max_count'] = usergroup_roles_stats[:max_count]
      data['user_group_roles_min_count'] = usergroup_roles_stats[:min_count]
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    private

    def usergroup_max_nesting_level
      # Use recursive CTE to find maximum nesting level of usergroups
      cte_sql = <<~SQL
        WITH RECURSIVE usergroup_hierarchy AS (
          -- Base case: root usergroups (not members of any other usergroup)
          SELECT id, 1 as level
          FROM usergroups
          WHERE id NOT IN (
            SELECT member_id
            FROM usergroup_members
            WHERE member_type = 'Usergroup'
          )
          UNION ALL
          -- Recursive case: usergroups that are members of other usergroups
          SELECT ug.id, uh.level + 1
          FROM usergroups ug
          INNER JOIN usergroup_members ugm ON ug.id = ugm.member_id
          INNER JOIN usergroup_hierarchy uh ON ugm.usergroup_id = uh.id
          WHERE ugm.member_type = 'Usergroup'
        )
      SQL

      sql_as_count('COALESCE(MAX(level) - 1, 0)', 'usergroup_hierarchy', cte: cte_sql)
    end

    def usergroup_roles_statistics
      # Query to get role counts per usergroup, including usergroups with 0 roles
      roles_per_usergroup = query(
        <<~SQL
          SELECT ug.id, COALESCE(ur.role_count, 0) as role_count
          FROM usergroups ug
          LEFT JOIN (
            SELECT owner_id, COUNT(*) as role_count
            FROM user_roles
            WHERE owner_type = 'Usergroup'
            GROUP BY owner_id
          ) ur ON ug.id = ur.owner_id
        SQL
      )

      if roles_per_usergroup.empty?
        { max_count: 0, min_count: 0 }
      else
        role_counts = roles_per_usergroup.map { |row| row['role_count'].to_i }
        { max_count: role_counts.max, min_count: role_counts.min }
      end
    end
  end
end
