module Reports
  class SmartProxiesContent < ForemanMaintain::Report
    metadata do
      description 'Report smart proxy metrics related to Katello'
      confine do
        feature(:katello)
      end
    end

    def run
      data_field('smart_proxies_syncing_library_count') { smart_proxies_syncing_library_count }
      data_field('smart_proxies_syncing_multiple_lifecycle_environments_count') do
        smart_proxies_syncing_multiple_lifecycle_environments_count
      end
    end

    private

    def smart_proxies_syncing_library_count
      # Exclude server smart proxy
      sql_count(<<-SQL, column: 'DISTINCT sp.id')
          smart_proxies sp
          INNER JOIN katello_capsule_lifecycle_environments kcle ON sp.id = kcle.capsule_id
          INNER JOIN katello_environments ke ON kcle.lifecycle_environment_id = ke.id
          WHERE ke.library = true AND sp.id != 1
      SQL
    end

    def smart_proxies_syncing_multiple_lifecycle_environments_count
      # Exclude server smart proxy
      sql_count(<<-SQL)
          (SELECT capsule_id, COUNT(DISTINCT lifecycle_environment_id) as env_count
           FROM katello_capsule_lifecycle_environments
           WHERE capsule_id != 1
           GROUP BY capsule_id
           HAVING COUNT(DISTINCT lifecycle_environment_id) > 1) multi_env_capsules
      SQL
    end
  end
end
