module Checks
  module Report
    class Compliance < ForemanMaintain::Report
      metadata do
        description 'Check if OpenSCAP is used'
      end

      def run
        self.data = {}
        mapping = {
          'policy':
            'foreman_openscap_policies',
          'policy_with_tailoring_file':
            'foreman_openscap_policies WHERE tailoring_file_id IS NOT NULL',
          'scap_contents':
            "foreman_openscap_scap_contents",
          'non_default_scap_contents':
            "foreman_openscap_scap_contents WHERE NOT original_filename LIKE 'ssg-rhel%-ds.xml'",
          'arf_report_last_year':
            "reports WHERE type = 'ForemanOpenscap::ArfReport'
                       AND reported_at < NOW() - INTERVAL '1 year'",
        }

        mapping.each do |k, query|
          data["compliance_#{k}_count"] = sql_count(query)
        end
      end
    end
  end
end
