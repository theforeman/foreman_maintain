module Report
  class ContentViews < ForemanMaintain::Report
    metadata do
      description 'Report metrics related to Katello content views'
      confine do
        feature(:katello)
      end
    end

    def run
      data_field('content_views_count') { content_views_count }
      data_field('content_views_rolling_count') { content_views_rolling_count }
      data_field('content_views_rolling_using_library_count') do
        rolling_content_views_using_library_count
      end
      data_field('content_views_rolling_using_lifecycle_environments_count') do
        rolling_content_views_using_lifecycle_environments_count
      end
      data_field('content_views_composite_count') { content_views_composite_count }
    end

    private

    def content_views_count
      sql_count(<<-SQL)
        katello_content_views
        WHERE \"default\" = false
          AND rolling = false
          AND composite = false
          AND generated_for = 0
      SQL
    end

    def content_views_rolling_count
      sql_count("katello_content_views WHERE rolling = true")
    end

    def rolling_content_views_using_library_count
      sql_as_count(
        "COUNT(DISTINCT cv.id)",
        <<~SQL
          katello_content_views AS cv
            INNER JOIN katello_content_view_environments AS cve ON cv.id = cve.content_view_id
            INNER JOIN katello_environments AS env ON cve.environment_id = env.id
            WHERE cv.rolling = true AND env.library = true
        SQL
      )
    end

    def rolling_content_views_using_lifecycle_environments_count
      sql_as_count(
        "COUNT(DISTINCT cv.id)",
        <<~SQL
          katello_content_views AS cv
            INNER JOIN katello_content_view_environments AS cve ON cv.id = cve.content_view_id
            INNER JOIN katello_environments AS env ON cve.environment_id = env.id
            WHERE cv.rolling = true AND env.library = false
        SQL
      )
    end

    def content_views_composite_count
      sql_count("katello_content_views WHERE composite = true")
    end
  end
end
