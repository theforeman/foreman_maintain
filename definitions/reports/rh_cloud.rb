module Reports
  class Rhcloud < ForemanMaintain::Report
    metadata do
      description 'Check if rh_cloud is enabled and what features are in use'
      confine do
        feature(:rh_cloud)
      end
    end

    # rubocop:disable Metrics/MethodLength
    def run
      data_field('rh_cloud_hosts_count') do
        rh_cloud_hosts_count
      end

      data_field('rh_cloud_mismatched_hosts_count') do
        rh_cloud_mismatched_hosts_count
      end

      data_field('rh_cloud_total_hits') do
        rh_cloud_total_hits
      end

      data_field('rh_cloud_mismatched_auto_delete') do
        rh_cloud_mismatched_auto_delete
      end

      data_field('rh_cloud_obfuscate_inventory_hostnames') do
        obfuscate_inventory_hostnames_setting
      end

      data_field('rh_cloud_obfuscate_inventory_ips') do
        obfuscate_inventory_ips_setting
      end

      data_field('rh_cloud_minimal_data_collection') do
        minimal_data_collection
      end

      data_field('rh_cloud_exclude_host_package_info') do
        exclude_host_package_info
      end

      data_field('rh_cloud_connector_enabled') do
        cloud_connector_enabled
      end

      data_field('rh_cloud_inventory_upload_enabled') do
        inventory_upload_enabled
      end

      data_field('rh_cloud_recommendations_sync_enabled') do
        recommendations_sync_enabled
      end
    end
    # rubocop:enable Metrics/MethodLength

    private

    def rh_cloud_hosts_count
      sql_count('hosts INNER JOIN insights_facets ON hosts.id = insights_facets.host_id')
    end

    def rh_cloud_mismatched_hosts_count
      sql_count('insights_missing_hosts')
    end

    def rh_cloud_total_hits
      sql_count('hosts INNER JOIN insights_hits ON hosts.id = insights_hits.host_id')
    end

    def obfuscate_inventory_hostnames_setting
      !!sql_setting('obfuscate_inventory_hostnames')
    end

    def obfuscate_inventory_ips_setting
      !!sql_setting('obfuscate_inventory_ips')
    end

    def minimal_data_collection
      !!sql_setting('insights_minimal_data_collection')
    end

    def exclude_host_package_info
      !!sql_setting('exclude_installed_packages')
    end

    def rh_cloud_mismatched_auto_delete
      !!sql_setting('allow_auto_insights_mismatch_delete')
    end

    def cloud_connector_enabled
      !!sql_setting('rhc_instance_id')
    end

    def inventory_upload_enabled
      !sql_setting('allow_auto_inventory_upload')
    end

    def recommendations_sync_enabled
      !sql_setting('allow_auto_insights_sync')
    end
  end
end
