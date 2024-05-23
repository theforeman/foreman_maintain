module Checks
  module Report
    class CheckVmwareUsage < ForemanMaintain::ReportCheck
      metadata do
        description 'Check if vmware compute resource is used'
        tags :report
      end

      def run
        count = sql_count("SELECT COUNT(*) FROM compute_resources WHERE type = 'Foreman::Model::Vmware'")
        self.data = { "compute_resource_vmware_count": count }
      end
    end
  end
end
