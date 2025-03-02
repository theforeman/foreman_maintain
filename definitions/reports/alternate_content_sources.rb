module Checks
  module Report
    class AlternateContentSources < ForemanMaintain::Report
      metadata do
        description 'Facts about ACSs'
        confine do
          feature(:katello)
        end
      end

      def run
        data_field('custom_alternate_content_sources_count') { custom_alternate_content_sources }
        data_field('simplified_alternate_content_sources_count') do
          simplified_alternate_content_sources
        end
        data_field('rhui_alternate_content_sources_count') { rhui_alternate_content_sources }
        data_field('yum_alternate_content_sources_count') { yum_alternate_content_sources }
        data_field('file_alternate_content_sources_count') { file_alternate_content_sources }
      end

      def custom_alternate_content_sources
        query =
          query(
            <<-SQL
              SELECT count(*) as custom_acs_count FROM "katello_alternate_content_sources"
                WHERE "katello_alternate_content_sources"."alternate_content_source_type" = 'custom'
            SQL
          )
        query.first['custom_acs_count'].to_i
      end

      def simplified_alternate_content_sources
        query =
          query(
            <<-SQL
              SELECT count(*) as simplified_acs_count FROM "katello_alternate_content_sources"
                WHERE "katello_alternate_content_sources"."alternate_content_source_type" = 'simplified'
            SQL
          )
        query.first['simplified_acs_count'].to_i
      end

      def rhui_alternate_content_sources
        query =
          query(
            <<-SQL
              SELECT count(*) as rhui_acs_count FROM "katello_alternate_content_sources"
                WHERE "katello_alternate_content_sources"."alternate_content_source_type" = 'rhui'
            SQL
          )
        query.first['rhui_acs_count'].to_i
      end

      def yum_alternate_content_sources
        query =
          query(
            <<-SQL
              SELECT count(*) as yum_acs_count FROM "katello_alternate_content_sources" WHERE "katello_alternate_content_sources"."content_type" = 'yum'
            SQL
          )
        query.first['yum_acs_count'].to_i
      end

      def file_alternate_content_sources
        query =
          query(
            <<-SQL
              SELECT count(*) as file_acs_count FROM "katello_alternate_content_sources" WHERE "katello_alternate_content_sources"."content_type" = 'file'
            SQL
          )
        query.first['file_acs_count'].to_i
      end
    end
  end
end
