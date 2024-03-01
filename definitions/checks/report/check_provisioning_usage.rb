module Checks
  module Report
    class CheckProvisioningUsage < ForemanMaintain::Check
      metadata do
        description 'Count hosts that have been provisioned in the last 3 months.'
        tags :report
      end

      def run
        count = feature(:foreman_database).query(self.class.query_for_provisioning_usage)
        result = count.first['count'].to_i

        self.data = { managed_hosts_created_in_last_3_months: result }
      end


      def self.query_for_provisioning_usage
        <<-SQL
          SELECT COUNT(*) FROM hosts WHERE managed = true AND created_at >= current_date - interval '3 months'
        SQL
      end
    end
  end
end
