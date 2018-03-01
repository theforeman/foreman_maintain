class Features::ForemanOpenscap < ForemanMaintain::Feature
  metadata do
    label :foreman_openscap

    confine do
      check_min_version('tfm-rubygem-foreman_openscap', '0.5.3')
    end
  end

  def report_ids_without_host
    reports_without_attribute('host_id')
  end

  def report_ids_without_proxy
    reports_without_attribute('openscap_proxy_id')
  end

  def report_ids_without_policy
    sql = <<-SQL
      SELECT id
      FROM reports
      WHERE id
        NOT IN (
          SELECT reports.id
          FROM reports INNER JOIN foreman_openscap_policy_arf_reports
                       ON reports.id = foreman_openscap_policy_arf_reports.arf_report_id
          WHERE reports.type = 'ForemanOpenscap::ArfReport'
        )
        AND type = 'ForemanOpenscap::ArfReport'
    SQL
    execute_ids_query sql
  end

  def delete_reports(ids)
    feature(:foreman_database).psql(<<-SQL)
      BEGIN;
        DELETE FROM reports WHERE id IN (#{ids.join(', ')});
        DELETE FROM foreman_openscap_policy_arf_reports WHERE arf_report_id IN (#{ids.join(', ')});
      COMMIT;
    SQL
  end

  private

  def reports_without_attribute(attr)
    sql = <<-SQL
      SELECT id
      FROM reports
      WHERE type = 'ForemanOpenscap::ArfReport' AND #{attr} IS NULL
    SQL
    execute_ids_query sql
  end

  def execute_ids_query(sql)
    feature(:foreman_database).query(sql).map { |item| item['id'].to_i } || []
  end
end
