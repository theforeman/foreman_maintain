module Procedures::Candlepin
  class DeleteOrphanedRecordsFromEnvContent < ForemanMaintain::Procedure
    metadata do
      label :cp_env_content_delete_orphaned_records
      description 'Delete orphaned record(s) with null content'
    end

    def run
      with_spinner('Deleting cp_env_content record(s) with null content') do |spinner|
        content_ids = feature(:candlepin).content_ids_with_null_content_from_cp_env_content
        if content_ids.empty?
          spinner.update 'No any orphaned record(s) with null content found'
        else
          spinner.update "Total #{content_ids.length} records with null content"
          logger.info "Content ids with null content found in cp_env_content - #{content_ids}"
          spinner.update 'Deleting record(s) from cp_env_content table'
          feature(:candlepin).delete_orphaned_records_from_cp_env_content(content_ids)
        end
      end
    end
  end
end
