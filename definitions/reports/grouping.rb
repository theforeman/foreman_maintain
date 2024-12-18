module Checks
  module Report
    class Grouping < ForemanMaintain::Report
      metadata do
        description 'Check how resources are grouped'
      end

      # rubocop:disable Metrics/AbcSize
      def run
        self.data = {}
        data['host_collections_count'] = sql_count('katello_host_collections')
        data['host_collections_with_limit_count'] = sql_count("katello_host_collections
                                                               WHERE unlimited_hosts = 'f'")
        hostgroup = sql_count('hostgroups')
        hostgroup_nest_level = sql_as_count(
          "COALESCE(MAX((CHAR_LENGTH(ancestry) - CHAR_LENGTH(REPLACE(ancestry, '/', '')))) + 2, 1)",
          'hostgroups'
        )
        data['hostgroup_nesting'] = hostgroup_nest_level > 1
        data['hostgroup_max_nesting_level'] = hostgroup.zero? ? 0 : hostgroup_nest_level

        data['use_selectable_columns'] = sql_count('table_preferences') > 0

        if table_exists('config_groups')
          data['config_group_count'] = sql_count('config_groups')
        end
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
