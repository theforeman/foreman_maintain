module Reports
  class ImageModeHosts < ForemanMaintain::Report
    metadata do
      description 'Report number of image mode hosts registered by operating system'
      confine do
        feature(:katello)
      end
    end

    def run
      merge_data('image_mode_hosts_by_os_count') { image_mode_hosts_by_os_count }
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
  end
end
