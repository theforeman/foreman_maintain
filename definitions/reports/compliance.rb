module Checks
  module Report
    class Compliance < ForemanMaintain::Report
      metadata do
        description 'Check if OpenSCAP is used'
      end

      def run
        data = {}
        data['compliance_policy_count'] = sql_count('foreman_openscap_policies')
        data['compliance_policy_with_tailoring_file_count'] = sql_count('foreman_openscap_policies WHERE tailoring_file_id IS NOT NULL')
        data['compliance_scap_contents_count'] = sql_count("foreman_openscap_scap_contents")
        data['compliance_non_default_scap_contents_count'] = sql_count("foreman_openscap_scap_contents WHERE NOT original_filename LIKE 'ssg-rhel%-ds.xml'")
        data['compliance_arf_report_last_year_count'] = sql_count("reports WHERE type = 'ForemanOpenscap::ArfReport' AND reported_at < NOW() - INTERVAL '1 year'")

        self.data = data
      end
    end
  end
end
