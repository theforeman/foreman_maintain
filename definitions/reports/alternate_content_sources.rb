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
        sql_count(
          "katello_alternate_content_sources WHERE alternate_content_source_type = 'custom'"
        )
      end

      def simplified_alternate_content_sources
        sql_count(
          "katello_alternate_content_sources WHERE alternate_content_source_type = 'simplified'"
        )
      end

      def rhui_alternate_content_sources
        sql_count("katello_alternate_content_sources WHERE alternate_content_source_type = 'rhui'")
      end

      def yum_alternate_content_sources
        sql_count("katello_alternate_content_sources WHERE content_type = 'yum'")
      end

      def file_alternate_content_sources
        sql_count("katello_alternate_content_sources WHERE content_type = 'file'")
      end
    end
  end
end
