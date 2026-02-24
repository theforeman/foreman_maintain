module Reports
  class ContentExport < ForemanMaintain::Report
    metadata do
      description 'Report metrics related to Katello content exports'
      confine do
        feature(:katello)
      end
    end

    # rubocop:disable Metrics/LineLength
    def run
      data_field('export_repository_histories_count') { export_repository_histories_count }
      data_field('export_content_view_version_histories_count') { export_content_view_version_histories_count }
      data_field('export_library_histories_count') { export_library_histories_count }
      data_field('export_complete_count') { export_complete_count }
      data_field('export_incremental_count') { export_incremental_count }
      data_field('export_format_syncable_count') { export_format_syncable_count }
      data_field('export_format_importable_count') { export_format_importable_count }
    end
    # rubocop:enable Metrics/LineLength

    private

    def cv_count_generated_for
      sql_count(<<-SQL)
        information_schema.columns
        WHERE table_name = 'katello_content_views'
          AND column_name = 'generated_for'
      SQL
    end

    def cvv_count_metadata
      sql_count(<<-SQL)
        information_schema.columns
        WHERE table_name = 'katello_content_view_version_export_histories'
          AND column_name = 'metadata'
      SQL
    end

    def export_repository_histories_count
      return 0 unless table_exists('katello_content_view_version_export_histories')
      return 0 unless table_exists('katello_content_view_versions')
      return 0 unless table_exists('katello_content_views')
      return 0 unless cv_count_generated_for > 0

      base_join = <<-SQL
        katello_content_view_version_export_histories h
        INNER JOIN katello_content_view_versions cvv ON h.content_view_version_id = cvv.id
        INNER JOIN katello_content_views cv ON cvv.content_view_id = cv.id
      SQL
      sql_count(<<-SQL)
        #{base_join}
        WHERE cv.generated_for IN ('repository_export', 'repository_export_syncable')
      SQL
    end

    def export_content_view_version_histories_count
      return 0 unless table_exists('katello_content_view_version_export_histories')
      sql_count('katello_content_view_version_export_histories')
    end

    def export_library_histories_count
      return 0 unless table_exists('katello_content_view_version_export_histories')
      return 0 unless table_exists('katello_content_view_versions')
      return 0 unless table_exists('katello_content_views')
      return 0 unless cv_count_generated_for > 0

      base_join = <<-SQL
        katello_content_view_version_export_histories h
        INNER JOIN katello_content_view_versions cvv ON h.content_view_version_id = cvv.id
        INNER JOIN katello_content_views cv ON cvv.content_view_id = cv.id
      SQL
      sql_count(<<-SQL)
        #{base_join}
        WHERE cv.generated_for IN ('library_export', 'library_export_syncable')
      SQL
    end

    def export_complete_count
      return 0 unless table_exists('katello_content_view_version_export_histories')
      sql_count("katello_content_view_version_export_histories WHERE export_type = 'complete'")
    end

    def export_incremental_count
      return 0 unless table_exists('katello_content_view_version_export_histories')
      sql_count("katello_content_view_version_export_histories WHERE export_type = 'incremental'")
    end

    def export_format_syncable_count
      return 0 unless table_exists('katello_content_view_version_export_histories')
      return 0 unless cvv_count_metadata > 0

      sql_count(<<-SQL)
        katello_content_view_version_export_histories
        WHERE metadata LIKE '%:format: syncable%'
          OR metadata LIKE '%format: syncable%'
      SQL
    end

    def export_format_importable_count
      return 0 unless table_exists('katello_content_view_version_export_histories')
      return 0 unless cvv_count_metadata > 0

      sql_count(<<-SQL)
        katello_content_view_version_export_histories
        WHERE metadata LIKE '%:format: importable%'
          OR metadata LIKE '%format: importable%'
      SQL
    end
  end
end
