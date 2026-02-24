module Reports
  class ImageModeHosts < ForemanMaintain::Report
    metadata do
      description 'Report metrics related to use of image mode'
      confine do
        feature(:katello)
      end
    end

    def run
      merge_data('image_mode_hosts_by_os_count') { image_mode_hosts_by_os_count }
      data_field('remote_execution_transient_package_actions_count') { transient_actions_count }
      data_field('host_installed_packages_transient_count') do
        host_installed_packages_transient_count
      end
      data_field('host_installed_packages_persistent_count') do
        host_installed_packages_persistent_count
      end
    end

    # OS usage on image mode hosts
    def image_mode_hosts_by_os_count
      query(
        <<-SQL
          select max(operatingsystems.name) as os_name, count(*) as hosts_count
          from hosts inner join operatingsystems on operatingsystem_id = operatingsystems.id inner join katello_content_facets on hosts.id = katello_content_facets.host_id
          where bootc_booted_digest is not null
          group by operatingsystems.name
        SQL
      ).
        to_h { |row| [row['os_name'], row['hosts_count'].to_i] }
    end

    def transient_actions_count
      cte = <<~CTE
        WITH bootc_hosts AS (
          SELECT hosts.id FROM hosts
          INNER JOIN katello_content_facets AS kcf ON hosts.id = kcf.host_id
          WHERE kcf.bootc_booted_digest IS NOT NULL
        )
      CTE

      sql = <<~SQL
        job_invocations AS ji
          INNER JOIN remote_execution_features AS ref ON ji.remote_execution_feature_id = ref.id
          INNER JOIN template_invocations AS ti ON ji.id = ti.job_invocation_id
          INNER JOIN bootc_hosts ON bootc_hosts.id = ti.host_id
          WHERE ref.label LIKE 'katello_package%'
             OR ref.label LIKE 'katello_errata%'
             OR ref.label LIKE 'katello_group%'
      SQL

      sql_count(sql, cte: cte)
    end

    def host_installed_packages_transient_count
      sql_count("katello_host_installed_packages WHERE persistence = 'transient'")
    end

    def host_installed_packages_persistent_count
      sql_count("katello_host_installed_packages WHERE persistence = 'persistent'")
    end
  end
end
