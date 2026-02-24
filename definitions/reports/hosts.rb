module Reports
  class Hosts < ForemanMaintain::Report
    metadata do
      description 'Report metrics related to hosts'
    end

    def run
      data_field('hosts_multi_cv_count') { hosts_multi_cv_count }
      data_field('hosts_multi_cv_with_rolling_cv_count') { hosts_multi_cv_with_rolling_cv_count }
      data_field('hosts_with_assigned_smart_proxy_count') { hosts_with_assigned_smart_proxy_count }
    end

    private

    def hosts_multi_cv_count
      sql_as_count(
        "COUNT(*)",
        <<~SQL
          (
            SELECT content_facet_id
            FROM katello_content_view_environment_content_facets
            GROUP BY content_facet_id
            HAVING COUNT(*) > 1
          ) AS multi_cve_hosts
        SQL
      )
    end

    def hosts_multi_cv_with_rolling_cv_count
      sql_as_count(
        "COUNT(DISTINCT cf.content_facet_id)",
        <<~SQL
          katello_content_view_environment_content_facets AS cf
            INNER JOIN katello_content_view_environments AS cve ON cf.content_view_environment_id = cve.id
            INNER JOIN katello_content_views AS cv ON cve.content_view_id = cv.id
            WHERE cf.content_facet_id IN (
              SELECT content_facet_id
              FROM katello_content_view_environment_content_facets
              GROUP BY content_facet_id
              HAVING COUNT(*) > 1
            )
            AND cv.rolling = true
        SQL
      )
    end

    def hosts_with_assigned_smart_proxy_count
      # Excludes smart proxy id 1 which is the server itself
      sql_count(<<-SQL)
        katello_content_facets
        WHERE content_source_id IS NOT NULL
          AND content_source_id != 1
      SQL
    end
  end
end
