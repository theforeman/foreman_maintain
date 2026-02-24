module Reports
  class SmartProxies < ForemanMaintain::Report
    metadata do
      description 'Report smart proxy metrics'
    end

    def run
      data_field('smart_proxies_count') { smart_proxies_count }
      merge_data('smart_proxies_creation_date') { smart_proxies_creation_date }
      data_field('smart_proxies_with_assigned_hosts_count') do
        smart_proxies_with_assigned_hosts_count
      end
      data_field('smart_proxies_assigned_hosts_count_min') do
        smart_proxies_assigned_hosts_count_min
      end
      data_field('smart_proxies_assigned_hosts_count_median') do
        smart_proxies_assigned_hosts_count_median
      end
      data_field('smart_proxies_assigned_hosts_count_average') do
        smart_proxies_assigned_hosts_count_average
      end
      data_field('smart_proxies_assigned_hosts_count_max') do
        smart_proxies_assigned_hosts_count_max
      end
    end

    private

    def smart_proxies_count
      # Exclude server smart proxy
      sql_count('smart_proxies WHERE id != 1')
    end

    def smart_proxies_creation_date
      query("select id, created_at from smart_proxies").to_h do |row|
        [row['id'], row['created_at']]
      end
    end

    def smart_proxies_with_assigned_hosts_count
      # Exclude server smart proxy
      sql_count(
        <<-SQL
            (SELECT DISTINCT content_source_id
              FROM katello_content_facets
              WHERE content_source_id IS NOT NULL AND content_source_id != 1
            ) AS smart_proxies_with_hosts
        SQL
      )
    end

    def smart_proxies_assigned_hosts_count_min
      # Exclude server smart proxy
      result = query(
        <<-SQL
            SELECT MIN(host_count) as min_count
            FROM (
              SELECT COUNT(*) as host_count
              FROM katello_content_facets
              WHERE content_source_id IS NOT NULL AND content_source_id != 1
              GROUP BY content_source_id
            ) AS counts
        SQL
      ).first
      result ? result['min_count'].to_i : 0
    end

    def smart_proxies_assigned_hosts_count_median
      # Exclude server smart proxy
      result = query(
        <<-SQL
            SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY host_count) as median_count
            FROM (
              SELECT COUNT(*) as host_count
              FROM katello_content_facets
              WHERE content_source_id IS NOT NULL AND content_source_id != 1
              GROUP BY content_source_id
            ) AS counts
        SQL
      ).first
      result ? result['median_count'].to_f : 0.0
    end

    def smart_proxies_assigned_hosts_count_average
      # Exclude server smart proxy
      result = query(
        <<-SQL
            SELECT AVG(host_count) as avg_count
            FROM (
              SELECT COUNT(*) as host_count
              FROM katello_content_facets
              WHERE content_source_id IS NOT NULL AND content_source_id != 1
              GROUP BY content_source_id
            ) AS counts
        SQL
      ).first
      result ? result['avg_count'].to_f : 0.0
    end

    def smart_proxies_assigned_hosts_count_max
      # Exclude server smart proxy
      result = query(
        <<-SQL
            SELECT MAX(host_count) as max_count
            FROM (
              SELECT COUNT(*) as host_count
              FROM katello_content_facets
              WHERE content_source_id IS NOT NULL AND content_source_id != 1
              GROUP BY content_source_id
            ) AS counts
        SQL
      ).first
      result ? result['max_count'].to_i : 0
    end
  end
end
