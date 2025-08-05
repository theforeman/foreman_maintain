module Reports
  class Grouping < ForemanMaintain::Report
    metadata do
      description 'Check how resources are grouped'
    end

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

      # Calculate maximum usergroup nesting level
      data_field('usergroup_max_nesting_level') { usergroup_max_nesting_level }
    end

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
  end
end
