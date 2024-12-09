module Checks
  module Report
    class Grouping < ForemanMaintain::Report
      metadata do
        description 'Check how resources are grouped'
      end

      def run
        collection_count = sql_count('katello_host_collections')
        collection_count_with_limit = sql_count("katello_host_collections
                                                 WHERE unlimited_hosts = 'f'")
        hostgroup = sql_count('hostgroups')
        sql = <<~SQL
          SELECT COALESCE(MAX((CHAR_LENGTH(ancestry) - CHAR_LENGTH(REPLACE(ancestry, '/', '')))) + 2, 1) AS count
          FROM hostgroups
        SQL
        hostgroup_nest_level = sql_count(sql)
        table_preference_count = sql_count('table_preferences')

        if table_exists('config_groups')
          config_group_count = sql_count('config_groups')
        end
        self.data = { 'host_collections_count': collection_count,
                      'host_collections_count_with_limit': collection_count_with_limit,
                      'hostgroup_count': hostgroup,
                      'hostgroup_nesting': hostgroup_nest_level > 1,
                      'hostgroup_max_nesting_level': hostgroup.zero? ? 0 : hostgroup_nest_level,
                      'use_selectable_columns': table_preference_count > 0,
                      'config_group_count': config_group_count || 0 }
      end
    end
  end
end
