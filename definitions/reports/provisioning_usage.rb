module Checks
  module Report
    class ProvisioningUsage < ForemanMaintain::Report
      metadata do
        description 'Count hosts that have been provisioned in the last 3 months.'
      end

      def run
        count = sql_count("SELECT COUNT(*) FROM hosts WHERE managed = true AND created_at >= current_date - interval '3 months'")
        result = count

        self.data = { managed_hosts_created_in_last_3_months: result }
      end
    end
  end
end
