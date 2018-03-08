module Procedures::Candlepin
  class DeleteOrphanedRecordsFromEnvContent < ForemanMaintain::Procedure
    metadata do
      description 'Delete orphaned record(s) from cp_env_content with unresolvable content'
      label :candlepin_delete_orphaned_records_from_env_content

      confine do
        feature(:candlepin_database) &&
          feature(:downstream) &&
          feature(:downstream).current_minor_version == '6.2' &&
          feature(:candlepin_database).table_exist?('cp_env_content')
      end
    end

    def run
      with_spinner('Deleting cp_env_content record(s) with unresolvable content') do |spinner|
        spinner.update 'Finding cp_env_content records with unresolvable content'
        env_content_ids = feature(:candlepin_database).env_content_ids_with_null_content
        if env_content_ids.empty?
          spinner.update 'No orphaned records found'
        else
          spinner.update 'Taking a backup of the candlepin database'
          feature(:candlepin_database).perform_backup

          puts "Total #{env_content_ids.length} records with unresolvable content"
          spinner.update 'Deleting record(s) from cp_env_content table'
          feature(:candlepin_database).delete_records_by_ids(
            'cp_env_content', env_content_ids
          )
        end
      end
    end
  end
end
